# Item Purchase Tool

Hello, my name is **Roman Parubov**.  
I developed this project as a **test assignment for Truesolv**.

## Overview
The **Item Purchase Tool** is a Salesforce Lightning Web Components (LWC) + Apex application that enables users to search, filter, and purchase items directly from an **Account** context. It supports a complete purchase workflow — from browsing items to adding them to a cart, checking out, and automatically calculating totals.

This project fully implements the **"Test Task – Item Purchase Tool"** requirements, including:

- **Account integration** – Launch from Account layout and display Account details
- **Search & filtering** – Filter by Family and Type, search by Name/Description
- **Cart management** – Add, view, and remove items; checkout to create purchase records
- **Purchase calculation** – Automatic calculation of TotalItems and GrandTotal via Apex Trigger
- **Item creation** – Managers can create items with optional image auto-fill from Unsplash API
- **Image refresh** – Ability to update an item’s image via Unsplash API
- **Navigation** – Redirect to created Purchase__c record after checkout

---

## Features Implemented

## How to Open the Item Purchase Tool from Account Layout

1. Open any Account record (example: **Acme Test**).

   <img width="1861" height="180" alt="image" src="https://github.com/user-attachments/assets/85e637cb-b8cd-48a5-a6a6-1c02d1340839" />


2. Click the dropdown button (▾) in the top-right corner and select **Open Item Purchase Tool**.

   <img width="586" height="457" alt="image" src="https://github.com/user-attachments/assets/797366b1-6e7a-4c74-8d5c-41d466fc9f8d" />


---

### User Features
- **Open from Account layout**  
  Custom button opens the tool in a new tab, passing the Account Id.

- **Account details**  
  Display Name, Account Number, and Industry on the page.

- **Item search & filters**  
  - Search by Name and Description  
  - Filter by Family__c and Type__c (picklist values dynamically loaded from schema)  
  - Display the number of listed items in the filter section

- **Item details modal**  
  View full item details with image. Refresh image via Unsplash API.

- **Cart functionality**  
  - Add items from the search list or details modal  
  - View cart in a modal table with line totals  
  - Checkout selected or all cart items

- **Checkout process**  
  Creates:
  - `Purchase__c` record linked to Account  
  - `PurchaseLine__c` records for each cart line  

- **Automatic totals**  
  Trigger recalculates `TotalItems__c` and `GrandTotal__c` on Purchase__c after any PurchaseLine__c changes.

- **Manager-only item creation**  
  - "Create Item" button visible only for users with `IsManager__c = true`  
  - Auto image fill via Unsplash based on item name if `autoImage` is selected

---

## Technical Implementation

### Apex Classes
- **ItemController** – Main backend logic:
  - Get Account details
  - Get picklist values
  - Search items by filters
  - Create purchases and items
  - Refresh item images from Unsplash
  - Manager permission check

- **PurchaseLineTriggerHandler** – Business logic for recalculating totals.

- **UnsplashHttp** – Builds and sends authenticated requests to Unsplash API (supports test injection).

- **UnsplashJsonParser** – Extracts a specific image URL from Unsplash JSON response.

### Trigger
- **PurchaseLineTrigger** – After insert/update/delete/undelete on PurchaseLine__c calls `PurchaseLineTriggerHandler.recalc`.

### LWC Components
- **itemPurchaseApp** – Main application container; handles search, cart, checkout, and modal management.
- **itemTile** – Displays an item in the search results with details and add-to-cart actions.
- **cartModal** – Shows cart contents; supports selecting lines and checkout.
- **itemDetailsModal** – Shows item details and allows refreshing its image.
- **createItemModal** – Form to create a new item.
- **itemFilters** - Load all filters (types and familyes)

---

## Usage

1. Open an Account and click **Item Purchase Tool**.
   
   <img width="1869" height="745" alt="image" src="https://github.com/user-attachments/assets/b0e3028e-9a88-4385-b7e8-1cc602ea24ce" />

2. Search or filter items.

   <img width="499" height="182" alt="image" src="https://github.com/user-attachments/assets/9306367d-a978-4e16-93a6-9ebbfa573804" />

3. Click **Details** to view full info and refresh image.

   <img width="810" height="801" alt="image" src="https://github.com/user-attachments/assets/cf4de35b-9074-4e90-9342-c986d8dea19f" />

4. Click **Add to Cart** to add items.

   <img width="364" height="378" alt="image" src="https://github.com/user-attachments/assets/a825ef4d-55be-42ce-985c-a3776de011a7" />

5. Open the **Cart**, choose items which you want, and click **Checkout**.

   <img width="802" height="303" alt="image" src="https://github.com/user-attachments/assets/02fdc039-1e93-40d0-9ad2-d84691bf07ce" />

6. View the newly created Purchase__c record with related PurchaseLine__c records.

    <img width="1269" height="556" alt="image" src="https://github.com/user-attachments/assets/560926ce-2396-45b9-8936-4a0e05954844" />


---

## Additional Notes
- **Logging**: In a production scenario, it would be beneficial to add more detailed logging (e.g., debug or custom log records) for troubleshooting and monitoring.
- **Testing**: While the core functionality works, more comprehensive unit tests and integration tests should be implemented to cover edge cases and ensure long-term stability.
- **Admin User Creation**: After completing the task, an administrator user `dev@truesolv.com` was created in the Salesforce Developer instance for review purposes.
- **Unmanaged Package**: Sorry but I didn't have time to make unmanaged package, because my average test coverage across all Apex Classes and Triggers is 35%. And when I was writing it, the deadline had already been over. 
