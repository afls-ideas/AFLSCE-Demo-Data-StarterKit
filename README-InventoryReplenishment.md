# Inventory Replenishment (Tab 6)

Simulates the **non-user-initiated inventory replenishment** process in Life Sciences Cloud. A warehouse ships sample inventory to field reps, and the reps acknowledge receipt on the Sample Inventory Management page.

## How It Works

In a production environment, inventory replenishment is triggered by an integration system (ERP, SAP, etc.) that creates shipment records and pushes them to Salesforce. The field rep then sees a pending Transfer In on their Sample Inventory Management page and acknowledges receipt.

This tab automates the "integration side" of that flow so demo reps have shipments waiting for acknowledgement.

## What Gets Created

The Create button generates records in this order:

### Step 0: Warehouse Locations (`Location`)
One warehouse per country (11 total). Reuses existing warehouses if already present.

| Field | Value |
|---|---|
| `LocationType` | `Warehouse` |
| `IsInventoryLocation` | `true` |
| `Name` | `{Country} Sample Warehouse` |

Warehouse mapping: US, GB, FR (Paris), DE (German), IT (Italy), ES (Spain), JP (Japan), KR (Korea), BR (Brazil), MX (Mexico), AR (Argentina).

### Step 1: Gather Rep Data
Finds all users assigned to country territories via `UserTerritory2Association`, then looks up each rep's User Inventory `Location` and `Address` (created by the Samples tab). Reps without inventory locations are skipped.

### Step 2: Sample Products & Batches
Queries `Product2` records matching `IMMUNEXIS-{CC}-{dose}-SMPL` and maps each to its earliest-expiry `ProductionBatch`.

### Step 3: Shipments (`Shipment`)
One per rep. Simulates the warehouse shipping product to the rep.

| Field | Value |
|---|---|
| `ShipToName` | Rep's full name |
| `TrackingNumber` | `AFLSCE-Replenishment` (used for tagging/cleanup) |
| `OwnerId` | Rep's user ID |

### Step 4: Shipment Items (`ShipmentItem`)
One per product per rep (typically 2 per rep: 10mg and 15mg).

| Field | Value |
|---|---|
| `ShipmentId` | Links to rep's Shipment |
| `Product2Id` | Sample product |
| `Quantity` | `1000` |

### Step 5: Inventory Operations (`InventoryOperation`)
One Transfer In per rep. This is the record the rep sees on the Sample Inventory Management page under "Received Inventory Acknowledgements".

| Field | Value | Why |
|---|---|---|
| `OperationType` | `TransferIn` | Incoming shipment from warehouse |
| `ShipmentStatus` | `Created` | Must be `Created` (not `Shipped`) to stay pending |
| `Status` | _(not set)_ | Must be null so the rep can submit to complete it |
| `SourceLocationId` | Country warehouse | Where the shipment originates |
| `DestinationLocationId` | Rep's inventory Location | Where the shipment is going |
| `DestinationAddressId` | _(not set)_ | Rep selects this during acknowledgement |
| `Comment` | `AFLSCE-Replenishment` | Internal tag |
| `OwnerId` | Rep's user ID | Required for visibility on rep's page |

### Step 6: Product Transfers (`ProductTransfer`)
One per product per rep. These are the line items within the Transfer In.

| Field | Value | Why |
|---|---|---|
| `Status` | `Requested` | Standard initial status |
| `Product2Id` | Sample product | Which product is being transferred |
| `QuantitySent` | `1000` | Quantity shipped from warehouse |
| `QuantityReceived` | _(not set)_ | Rep fills this in during acknowledgement |
| `IsReceived` | `false` | Must be false; system sets true on acknowledgement |
| `QuantityUnitOfMeasure` | `Each` | Must match the destination `ProductItem` UOM |
| `DestinationLocationId` | Rep's inventory Location | Target location |
| `ShipmentId` | Links to rep's Shipment | Connects to the shipment |
| `InventoryOperationId` | Links to rep's IO | Groups transfers under one operation |
| `ProductionBatchId` | Earliest-expiry batch | Which batch the inventory comes from |
| `OwnerId` | Rep's user ID | Required for visibility |

## Critical Field Values for Acknowledgement

Getting the initial field values right is essential. If any of these are wrong, the rep either won't see the pending shipment or won't be able to submit the acknowledgement:

| What | Correct Value | What Happens If Wrong |
|---|---|---|
| IO `Status` | `null` (not set) | If `Completed`, the IO auto-closes and skips the acknowledgement flow |
| IO `ShipmentStatus` | `Created` | If `Shipped` or `Delivered`, the system may treat it as already processed |
| IO `DestinationAddressId` | `null` (not set) | Pre-setting this can interfere with the submit flow; let the rep pick it |
| PT `IsReceived` | `false` | If `true`, the system considers the transfer already acknowledged |
| PT `QuantityReceived` | `null` (not set) | If pre-set, there's nothing for the rep to confirm |
| PT `QuantityUnitOfMeasure` | Must match `ProductItem.QuantityUnitOfMeasure` | Validation error on submit if mismatched |
| All records `OwnerId` | Rep's user ID | Records won't appear on the rep's Sample Inventory Management page |

## End-User Acknowledgement Flow

After the admin clicks Create, each rep sees a pending Transfer In on their Sample Inventory Management page:

1. Open the **Sample Inventory Management** page (as the rep user)
2. In the **Received Inventory Acknowledgements** section, find the pending Transfer In
3. Click to open the Transfer In record
4. Set **Destination Address** (the rep's inventory storage address)
5. Set **Received Date Time**
6. Optionally update **Shipment Status** to `Delivered`
7. Click **Submit**

On submit, the system:
- Sets `InventoryOperation.Status = Completed`
- Sets `ProductTransfer.IsReceived = true` and populates `QuantityReceived`
- Updates `ProductItem.QuantityOnHand` at the destination location

## Prerequisites

Run **Tab 5 (Samples)** first. The Samples tab creates:
- User Inventory Locations and Addresses for each rep
- Sample Products (`Product2`) and Production Batches
- ProductItem records (with `QuantityUnitOfMeasure = Each`)

Without these, the replenishment tab has nothing to ship.

## Delete & Recreate

The Delete button removes all replenishment records in reverse dependency order:

1. `ProductTransfer` (by `ShipmentId`)
2. `ShipmentItem` (by `ShipmentId`)
3. `Shipment` (by `TrackingNumber = AFLSCE-Replenishment`)
4. `InventoryOperation` (by `SourceLocationId IN warehouse locations` and `OperationType = TransferIn`)

Warehouse `Location` records are **not** deleted (they may be shared with other features).

This allows you to repeatedly delete and recreate replenishment shipments for demo purposes.

## Tagging

| Object | Tag Field | Tag Value |
|---|---|---|
| `Shipment` | `TrackingNumber` | `AFLSCE-Replenishment` |
| `InventoryOperation` | `Comment` | `AFLSCE-Replenishment` |
| `ShipmentItem` | via `ShipmentId` | (child of tagged Shipment) |
| `ProductTransfer` | via `ShipmentId` | (child of tagged Shipment) |

## Architecture

```
DemoReplenishmentController.cls     Apex controller (all CRUD logic)
replenishmentSetup/                 LWC component
  replenishmentSetup.html             UI template (status, create/delete buttons, activity log)
  replenishmentSetup.js               Controller (wire getStatus, handleCreate, handleDelete)
  replenishmentSetup.js-meta.xml      Component metadata
```

The LWC is embedded in the main `demoDataAdmin` component as Tab 6 ("Inventory Replenishment"), between Samples and Scenario Builder.
