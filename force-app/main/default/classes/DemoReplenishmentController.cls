public without sharing class DemoReplenishmentController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final String REPLENISH_TAG = 'AFLSCE-Replenishment';
    private static final Decimal SHIPMENT_QTY = 1000;

    private static final Map<String, String> COUNTRY_TERRITORY = new Map<String, String>{
        'US' => 'US_COUNTRY', 'GB' => 'GB_COUNTRY', 'FR' => 'FR_COUNTRY',
        'DE' => 'DE_COUNTRY', 'IT' => 'IT_COUNTRY', 'ES' => 'ES_COUNTRY',
        'JP' => 'JP_COUNTRY', 'KR' => 'KR_COUNTRY', 'BR' => 'BR_COUNTRY',
        'MX' => 'MX_COUNTRY', 'AR' => 'AR_COUNTRY'
    };

    private static final Map<String, String> COUNTRY_WAREHOUSE = new Map<String, String>{
        'US' => 'US Sample Warehouse',
        'GB' => 'GB Sample Warehouse',
        'FR' => 'Paris Warehouse',
        'DE' => 'German Warehouse',
        'IT' => 'Italy Sample Warehouse',
        'ES' => 'Spain Sample Warehouse',
        'JP' => 'Japan Sample Warehouse',
        'KR' => 'Korea Sample Warehouse',
        'BR' => 'Brazil Sample Warehouse',
        'MX' => 'Mexico Sample Warehouse',
        'AR' => 'Argentina Sample Warehouse'
    };

    private static Set<Id> getTaggedShipmentIds() {
        Set<Id> ids = new Set<Id>();
        for (Shipment s : [SELECT Id FROM Shipment WHERE TrackingNumber = :REPLENISH_TAG]) {
            ids.add(s.Id);
        }
        return ids;
    }

    private static Set<Id> getWarehouseLocationIds() {
        Set<String> names = new Set<String>(COUNTRY_WAREHOUSE.values());
        Set<Id> ids = new Set<Id>();
        for (Schema.Location loc : [SELECT Id FROM Location
                WHERE LocationType = 'Warehouse' AND IsInventoryLocation = true AND Name IN :names]) {
            ids.add(loc.Id);
        }
        return ids;
    }

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            List<String> parts = new List<String>();

            Set<String> whNames = new Set<String>(COUNTRY_WAREHOUSE.values());
            Integer whCount = [SELECT COUNT() FROM Location
                WHERE LocationType = 'Warehouse' AND IsInventoryLocation = true
                AND Name IN :whNames];
            parts.add('Warehouses: ' + whCount);

            Set<Id> shipIds = getTaggedShipmentIds();
            parts.add('Shipments: ' + shipIds.size());

            if (!shipIds.isEmpty()) {
                Integer siCount = [SELECT COUNT() FROM ShipmentItem WHERE ShipmentId IN :shipIds];
                parts.add('Shipment Items: ' + siCount);
                Integer ptCount = [SELECT COUNT() FROM ProductTransfer WHERE ShipmentId IN :shipIds];
                parts.add('Product Transfers: ' + ptCount);
            } else {
                parts.add('Shipment Items: 0');
                parts.add('Product Transfers: 0');
            }

            Set<Id> whIds = getWarehouseLocationIds();
            Integer ioCount = 0;
            if (!whIds.isEmpty()) {
                ioCount = [SELECT COUNT() FROM InventoryOperation
                    WHERE OperationType = 'TransferIn' AND SourceLocationId IN :whIds];
            }
            parts.add('Inventory Operations: ' + ioCount);

            return String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createReplenishment() {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            Set<Id> existingShipIds = getTaggedShipmentIds();
            if (!existingShipIds.isEmpty()) {
                throw new AuraHandledException('Replenishment records already exist (' + existingShipIds.size() + ' shipments). Delete first to re-create.');
            }

            details.add('HEADER:Step 0 — Warehouse Locations');
            Map<String, Id> warehouseIds = ensureWarehouses(details, errors);

            details.add('HEADER:Step 1 — Gathering rep data');
            Map<Id, RepInfo> repMap = gatherRepData(details, errors);
            if (repMap.isEmpty()) {
                throw new AuraHandledException('No reps found. Run Samples setup first.');
            }

            details.add('HEADER:Step 2 — Sample products & batches');
            Map<String, List<Product2>> countryProducts = getCountryProducts();
            Map<Id, Id> productToBatch = getProductToBatch(countryProducts);
            details.add('Found ' + countryProducts.size() + ' countries with sample products');
            details.add('Matched ' + productToBatch.size() + ' products to production batches');

            details.add('HEADER:Step 3 — Shipments');
            details.add('Creating one Shipment per rep with ShipToName = rep name');
            Map<Id, Id> repToShipment = createShipments(repMap, details, errors);

            details.add('HEADER:Step 4 — Shipment Items');
            details.add('Creating one ShipmentItem per product per rep (qty=' + SHIPMENT_QTY.intValue() + ')');
            createShipmentItems(repMap, repToShipment, countryProducts, details, errors);

            details.add('HEADER:Step 5 — Inventory Operations (Transfer In)');
            details.add('OperationType=TransferIn, ShipmentStatus=Created (pending acknowledgement)');
            Map<Id, Id> repToIO = createInventoryOperations(repMap, warehouseIds, details, errors);

            details.add('HEADER:Step 6 — Product Transfers');
            details.add('One per product per rep — links Shipment, InventoryOperation, and ProductionBatch');
            createProductTransfers(repMap, repToShipment, repToIO, countryProducts, productToBatch, details, errors);

            String summary = errors.isEmpty()
                ? 'Replenishment created for ' + repMap.size() + ' reps.'
                : 'Completed with ' + errors.size() + ' error(s).';
            Map<String, Object> result = new Map<String, Object>{
                'summary' => summary,
                'details' => details,
                'errors' => errors
            };
            return JSON.serialize(result);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static String deleteReplenishment() {
        try {
            Integer deleted = 0;
            Set<Id> shipIds = getTaggedShipmentIds();

            if (!shipIds.isEmpty()) {
                List<ProductTransfer> pts = [SELECT Id FROM ProductTransfer WHERE ShipmentId IN :shipIds];
                if (!pts.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(pts, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }

                List<ShipmentItem> sis = [SELECT Id FROM ShipmentItem WHERE ShipmentId IN :shipIds];
                if (!sis.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(sis, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }

                List<Shipment> ships = [SELECT Id FROM Shipment WHERE Id IN :shipIds];
                if (!ships.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(ships, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            Set<Id> whIds = getWarehouseLocationIds();
            if (!whIds.isEmpty()) {
                List<InventoryOperation> ios = [SELECT Id FROM InventoryOperation
                    WHERE OperationType = 'TransferIn' AND SourceLocationId IN :whIds];
                if (!ios.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(ios, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            return 'Deleted ' + deleted + ' replenishment records.';
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting: ' + e.getMessage());
        }
    }

    private class RepInfo {
        public Id userId;
        public String userName;
        public String countryCode;
        public Id locationId;
        public Id addressId;
    }

    private static Map<String, Id> ensureWarehouses(List<String> details, List<String> errors) {
        Map<String, Id> warehouseIds = new Map<String, Id>();
        Set<String> warehouseNames = new Set<String>(COUNTRY_WAREHOUSE.values());

        for (Schema.Location loc : [SELECT Id, Name FROM Location
                WHERE LocationType = 'Warehouse' AND IsInventoryLocation = true
                AND Name IN :warehouseNames]) {
            warehouseIds.put(loc.Name, loc.Id);
        }

        List<Schema.Location> newWarehouses = new List<Schema.Location>();
        List<String> newNames = new List<String>();
        for (String cc : COUNTRY_WAREHOUSE.keySet()) {
            String whName = COUNTRY_WAREHOUSE.get(cc);
            if (!warehouseIds.containsKey(whName)) {
                Schema.Location loc = new Schema.Location();
                loc.Name = whName;
                loc.LocationType = 'Warehouse';
                loc.IsInventoryLocation = true;
                newWarehouses.add(loc);
                newNames.add(whName);
            }
        }

        if (!newWarehouses.isEmpty()) {
            Database.SaveResult[] results = Database.insert(newWarehouses, false);
            Integer created = 0;
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    warehouseIds.put(newNames[i], results[i].getId());
                    created++;
                } else if (errors.size() < 15) {
                    errors.add('Warehouse ' + newNames[i] + ': ' + results[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + created + ' new warehouses');
        }

        details.add(warehouseIds.size() + ' warehouses available');
        return warehouseIds;
    }

    private static Map<Id, RepInfo> gatherRepData(List<String> details, List<String> errors) {
        // Build country territory Id -> country code map
        Set<String> countryDevNames = new Set<String>(COUNTRY_TERRITORY.values());
        Map<Id, String> countryTerrIdToCC = new Map<Id, String>();
        Map<String, String> devNameToCC = new Map<String, String>();
        for (String cc : COUNTRY_TERRITORY.keySet()) {
            devNameToCC.put(COUNTRY_TERRITORY.get(cc), cc);
        }
        for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2 WHERE DeveloperName IN :countryDevNames]) {
            countryTerrIdToCC.put(t.Id, devNameToCC.get(t.DeveloperName));
        }

        // Walk hierarchy: country territories → all descendants (up to 5 levels)
        Map<Id, String> allTerrIdToCC = new Map<Id, String>();
        for (Id tId : countryTerrIdToCC.keySet()) {
            allTerrIdToCC.put(tId, countryTerrIdToCC.get(tId));
        }
        Set<Id> currentLevel = countryTerrIdToCC.keySet();
        for (Integer depth = 0; depth < 5 && !currentLevel.isEmpty(); depth++) {
            Set<Id> nextLevel = new Set<Id>();
            for (Territory2 child : [SELECT Id, ParentTerritory2Id FROM Territory2 WHERE ParentTerritory2Id IN :currentLevel]) {
                nextLevel.add(child.Id);
                String cc = allTerrIdToCC.get(child.ParentTerritory2Id);
                if (cc != null) {
                    allTerrIdToCC.put(child.Id, cc);
                }
            }
            currentLevel = nextLevel;
        }

        // Find reps assigned to any territory in the hierarchy
        Set<Id> allTerrIds = allTerrIdToCC.keySet();
        List<UserTerritory2Association> utas = [
            SELECT UserId, User.Name, Territory2Id, Territory2.DeveloperName
            FROM UserTerritory2Association
            WHERE Territory2Id IN :allTerrIds
        ];

        Map<Id, RepInfo> repMap = new Map<Id, RepInfo>();
        Set<Id> repIds = new Set<Id>();
        for (UserTerritory2Association uta : utas) {
            if (repMap.containsKey(uta.UserId)) continue;
            RepInfo ri = new RepInfo();
            ri.userId = uta.UserId;
            ri.userName = uta.User.Name;
            ri.countryCode = allTerrIdToCC.get(uta.Territory2Id);
            repMap.put(uta.UserId, ri);
            repIds.add(uta.UserId);
        }

        for (Schema.Location loc : [
            SELECT Id, PrimaryUserId, (SELECT Id FROM Addresses LIMIT 1)
            FROM Location
            WHERE PrimaryUserId IN :repIds AND LocationType = 'User Inventory' AND IsInventoryLocation = true
        ]) {
            RepInfo ri = repMap.get(loc.PrimaryUserId);
            if (ri != null) {
                ri.locationId = loc.Id;
                if (loc.Addresses != null && !loc.Addresses.isEmpty()) {
                    ri.addressId = loc.Addresses[0].Id;
                }
            }
        }

        Integer missing = 0;
        for (Id repId : new List<Id>(repMap.keySet())) {
            RepInfo ri = repMap.get(repId);
            if (ri.locationId == null) {
                repMap.remove(repId);
                missing++;
            }
        }
        if (missing > 0) {
            details.add('WARNING: ' + missing + ' rep(s) missing inventory Location — run Samples first');
        }
        details.add('SUCCESS:Found ' + repMap.size() + ' reps with inventory locations');
        return repMap;
    }

    private static Map<String, List<Product2>> getCountryProducts() {
        Map<String, List<Product2>> result = new Map<String, List<Product2>>();
        for (Product2 p : [SELECT Id, Name, ProductCode FROM Product2
                WHERE ProductCode LIKE 'IMMUNEXIS-%-SMPL' AND Family = 'Sample']) {
            String cc = p.ProductCode.substringAfter('IMMUNEXIS-').substringBefore('-');
            if (!result.containsKey(cc)) {
                result.put(cc, new List<Product2>());
            }
            result.get(cc).add(p);
        }
        return result;
    }

    private static Map<Id, Id> getProductToBatch(Map<String, List<Product2>> countryProducts) {
        Set<Id> allProductIds = new Set<Id>();
        for (List<Product2> prods : countryProducts.values()) {
            for (Product2 p : prods) allProductIds.add(p.Id);
        }

        Map<Id, Id> result = new Map<Id, Id>();
        if (!allProductIds.isEmpty()) {
            for (ProductionBatch pb : [SELECT Id, ProductId FROM ProductionBatch
                    WHERE ProductId IN :allProductIds ORDER BY ExpirationDate ASC]) {
                if (!result.containsKey(pb.ProductId)) {
                    result.put(pb.ProductId, pb.Id);
                }
            }
        }
        return result;
    }

    private static Map<Id, Id> createShipments(Map<Id, RepInfo> repMap, List<String> details, List<String> errors) {
        List<Shipment> ships = new List<Shipment>();
        List<Id> shipRepIds = new List<Id>();

        for (Id repId : repMap.keySet()) {
            RepInfo ri = repMap.get(repId);
            Shipment s = new Shipment();
            s.ShipToName = ri.userName;
            s.TrackingNumber = REPLENISH_TAG;
            s.OwnerId = ri.userId;
            ships.add(s);
            shipRepIds.add(repId);
        }

        Map<Id, Id> repToShipment = new Map<Id, Id>();
        Database.SaveResult[] results = Database.insert(ships, false);
        Integer created = 0;
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                repToShipment.put(shipRepIds[i], results[i].getId());
                created++;
            } else if (errors.size() < 15) {
                errors.add('Shipment for ' + repMap.get(shipRepIds[i]).userName + ': ' + results[i].getErrors()[0].getMessage());
            }
        }
        details.add('SUCCESS:Created ' + created + ' shipments');
        return repToShipment;
    }

    private static void createShipmentItems(Map<Id, RepInfo> repMap, Map<Id, Id> repToShipment,
            Map<String, List<Product2>> countryProducts, List<String> details, List<String> errors) {
        List<ShipmentItem> items = new List<ShipmentItem>();

        for (Id repId : repToShipment.keySet()) {
            RepInfo ri = repMap.get(repId);
            Id shipId = repToShipment.get(repId);
            List<Product2> prods = countryProducts.get(ri.countryCode);
            if (prods == null) continue;

            for (Product2 p : prods) {
                ShipmentItem si = new ShipmentItem();
                si.ShipmentId = shipId;
                si.Product2Id = p.Id;
                si.Quantity = SHIPMENT_QTY;
                items.add(si);
            }
        }

        if (!items.isEmpty()) {
            Database.SaveResult[] results = Database.insert(items, false);
            Integer created = 0;
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    created++;
                } else if (errors.size() < 15) {
                    errors.add('ShipmentItem: ' + results[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + created + ' shipment items');
        }
    }

    private static Map<Id, Id> createInventoryOperations(Map<Id, RepInfo> repMap,
            Map<String, Id> warehouseIds, List<String> details, List<String> errors) {
        List<InventoryOperation> ios = new List<InventoryOperation>();
        List<Id> ioRepIds = new List<Id>();

        for (Id repId : repMap.keySet()) {
            RepInfo ri = repMap.get(repId);
            String whName = COUNTRY_WAREHOUSE.get(ri.countryCode);
            Id whId = whName != null ? warehouseIds.get(whName) : null;

            InventoryOperation io = new InventoryOperation();
            io.OperationType = 'TransferIn';
            io.ShipmentStatus = 'Created';
            io.SourceLocationId = whId;
            io.DestinationLocationId = ri.locationId;
            io.Comment = REPLENISH_TAG;
            io.OwnerId = ri.userId;
            ios.add(io);
            ioRepIds.add(repId);
        }

        Map<Id, Id> repToIO = new Map<Id, Id>();
        Database.SaveResult[] results = Database.insert(ios, false);
        Integer created = 0;
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                repToIO.put(ioRepIds[i], results[i].getId());
                created++;
            } else if (errors.size() < 15) {
                errors.add('InventoryOperation for ' + repMap.get(ioRepIds[i]).userName + ': ' + results[i].getErrors()[0].getMessage());
            }
        }
        details.add('SUCCESS:Created ' + created + ' inventory operations');
        return repToIO;
    }

    private static void createProductTransfers(Map<Id, RepInfo> repMap, Map<Id, Id> repToShipment,
            Map<Id, Id> repToIO, Map<String, List<Product2>> countryProducts,
            Map<Id, Id> productToBatch, List<String> details, List<String> errors) {

        Set<Id> repLocIds = new Set<Id>();
        for (RepInfo ri : repMap.values()) repLocIds.add(ri.locationId);
        Set<Id> allProdIds = new Set<Id>();
        for (List<Product2> prods : countryProducts.values()) {
            for (Product2 p : prods) allProdIds.add(p.Id);
        }
        Map<String, String> piUom = new Map<String, String>();
        for (ProductItem pi : [SELECT Product2Id, LocationId, QuantityUnitOfMeasure
                FROM ProductItem WHERE Product2Id IN :allProdIds AND LocationId IN :repLocIds]) {
            piUom.put('' + pi.Product2Id + pi.LocationId, pi.QuantityUnitOfMeasure);
        }

        List<ProductTransfer> pts = new List<ProductTransfer>();

        for (Id repId : repToShipment.keySet()) {
            RepInfo ri = repMap.get(repId);
            Id shipId = repToShipment.get(repId);
            Id ioId = repToIO.get(repId);
            List<Product2> prods = countryProducts.get(ri.countryCode);
            if (prods == null) continue;

            for (Product2 p : prods) {
                ProductTransfer pt = new ProductTransfer();
                pt.Status = 'Requested';
                pt.Product2Id = p.Id;
                pt.QuantitySent = SHIPMENT_QTY;
                pt.IsReceived = false;
                pt.DestinationLocationId = ri.locationId;
                pt.ShipmentId = shipId;
                pt.InventoryOperationId = ioId;
                pt.OwnerId = ri.userId;
                String uom = piUom.get('' + p.Id + ri.locationId);
                pt.QuantityUnitOfMeasure = (uom != null) ? uom : 'Each';
                Id batchId = productToBatch.get(p.Id);
                if (batchId != null) {
                    pt.ProductionBatchId = batchId;
                }
                pts.add(pt);
            }
        }

        if (!pts.isEmpty()) {
            Database.SaveResult[] results = Database.insert(pts, false);
            Integer created = 0;
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    created++;
                } else if (errors.size() < 15) {
                    errors.add('ProductTransfer: ' + results[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + created + ' product transfers');
        }
    }
}
