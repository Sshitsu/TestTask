import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getAccount from '@salesforce/apex/ItemController.getAccount';
import getPicklistFilters from '@salesforce/apex/ItemController.getPicklistFilters';
import searchItems from '@salesforce/apex/ItemController.searchItems';
import createPurchase from '@salesforce/apex/ItemController.createPurchase';
import isCurrentUserManager from '@salesforce/apex/ItemController.isCurrentUserManager';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ItemPurchaseApp extends NavigationMixin(LightningElement) {

    @wire(CurrentPageReference) pageRef;
    account; filters; items = []; cart = [];
    isCartOpen = false; isDetailsOpen = false; selectedItem;
    searchText = ''; selectedFamilies = []; selectedTypes = [];
    isManager = false;
    isCreateOpen = false;

    openCreateItem(){ this.isCreateOpen = true; }

    get accountId(){ return this.pageRef?.state?.c__accountId; }

    connectedCallback(){ this.init(); }

    async init(){
        try {
            if(this.accountId){ this.account = await getAccount({ accountId: this.accountId }); }
            this.isManager = await isCurrentUserManager();
            this.filters = await getPicklistFilters();

            await this.doSearch();
        } catch(e) { /* toast + console */ }
    }

    handleDoSearch(e){
        const { searchText, families, types } = e.detail;
        this.searchText = searchText || '';
        this.selectedFamilies = families || [];
        this.selectedTypes = types || [];
        this.doSearch();
    }

    async doSearch(){
        console.log('doSearch called', this.searchText, this.selectedFamilies, this.selectedTypes);
        try {
            this.items = await searchItems({
                searchText: this.searchText,
                families: this.selectedFamilies,
                types: this.selectedTypes
            });
            console.log('items received', this.items);
        } catch(e) {
            console.error('searchItems error', e);
        }
    }


    handleSearchChange(e){ this.searchText = e.detail; this.doSearch(); }

    handleFilterChange(e){
        const { families, types } = e.detail;
        this.selectedFamilies = families; this.selectedTypes = types; this.doSearch();
    }

    handleShowDetails(e){ this.selectedItem = e.detail; this.isDetailsOpen = true; }
    closeDetails(){ this.isDetailsOpen = false; this.selectedItem = null; }

    handleAddToCart(e){
        const { id, name, price } = e.detail;
        const line = this.cart.find(l => l.itemId === id);

        if(line){
        line.amount += 1;
         this.cart = [...this.cart];
         } else {
         this.cart = [...this.cart,
         { itemId: id,
          name,
          amount: 1,
          unitCost: price }]; }
        this.dispatchEvent(new ShowToastEvent({ title: 'Added', message: 'Item added to cart', variant: 'success' }));
    }

    openCart(){ this.isCartOpen = true; }
    closeCart(){ this.isCartOpen = false; }

    async handleCheckout(){
        try{
            if(!this.account?.Id){
                  this.dispatchEvent(new ShowToastEvent({ title: 'No Account', message: 'Open from Account', variant: 'warning' }));
                  return;
            }
            const lines = (this.cart || []).map(l => ({
                  itemId: l.itemId,
                  amount: l.amount,
                  unitCost: l.unitCost
                }));
            const purchaseId = await createPurchase({ accountId: this.account.Id, lines });
            this[NavigationMixin.Navigate]({
                 type: 'standard__recordPage',
                 attributes: {
                   recordId: purchaseId,
                   objectApiName: 'Purchase__c',
                   actionName: 'view'
                 }
            });
        } catch(e){
            console.error(e);
            this.dispatchEvent(new ShowToastEvent({
               title: 'Checkout error',
               message: e?.body?.message || e.message,
               variant: 'error'
            }));
        }
    }
    closeCreateItem(){
      this.isCreateOpen = false;
    }

    handleItemCreated(e){
      this.isCreateOpen = false;
      try {
        this.dispatchEvent(
          new ShowToastEvent({ title: 'Item created', message: e?.detail?.id, variant: 'success' })
        );
      } catch {}
      this.doSearch();
    }
}