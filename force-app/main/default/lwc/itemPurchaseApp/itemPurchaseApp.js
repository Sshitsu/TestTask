import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getAccount from '@salesforce/apex/ItemController.getAccount';
import getPicklistFilters from '@salesforce/apex/ItemController.getPicklistFilters';
import searchItems from '@salesforce/apex/ItemController.searchItems';
import createPurchase from '@salesforce/apex/ItemController.createPurchase';
import isCurrentUserManager from '@salesforce/apex/ItemController.isCurrentUserManager';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ItemPurchaseApp extends NavigationMixin(LightningElement) {
  account; filters; items = []; cart = [];
  isCartOpen = false; isDetailsOpen = false; selectedItem;
  searchText = ''; selectedFamilies = []; selectedTypes = [];
  isManager = false;
  isCreateOpen = false;


  _accountId;

  get accountId() { return this._accountId; }

  connectedCallback(){ this.init(); }

  openCreateItem(){ this.isCreateOpen = true; }

  @wire(CurrentPageReference)
  parsePageRef(ref){
    if (!ref) return;
    const st   = ref.state || {};
    const attr = ref.attributes || {};
    const idFromUrl  = st.c__accountId;
    const idFromPage = attr.recordId;

    const newId = idFromUrl || idFromPage || null;
    if (newId && newId !== this._accountId) {
      this._accountId = newId;
      this.init();
    }


  }

  async init(){
    try {
      if(this.accountId){ this.account = await getAccount({ accountId: this.accountId }); }
      this.isManager = await isCurrentUserManager();
      this.filters = await getPicklistFilters();
      await this.doSearch();
    } catch(e) {
      console.error('init error', e);
      this.dispatchEvent(new ShowToastEvent({
        title: 'Init error',
        message: e?.body?.message || e.message,
        variant: 'error'
      }));
    }
  }

  handleDoSearch(e){
    const { searchText, families, types } = e.detail;
    this.searchText = searchText || '';
    this.selectedFamilies = families || [];
    this.selectedTypes = types || [];
    this.doSearch();
  }

  async doSearch(){
    try {
      this.items = await searchItems({
        searchText: this.searchText,
        families: this.selectedFamilies,
        types: this.selectedTypes
      });
    } catch(e) {
      console.error('searchItems error', e);
    }
  }

  handleSearchChange(e){ this.searchText = e.detail; this.doSearch(); }

  handleFilterChange(e){
    const { families, types } = e.detail;
    this.selectedFamilies = families;
    this.selectedTypes = types;
    this.doSearch();
  }

  handleShowDetails(e){ this.selectedItem = e.detail; this.isDetailsOpen = true; }
  closeDetails(){ this.isDetailsOpen = false; this.selectedItem = null; }

  handleAddToCart(e){
    const d = e.detail || {};
    const resolvedId = d.itemId || d.id || d.Id || d.item?.Id;

    console.log('add event detail =', d, 'resolvedId =', resolvedId);

    if (!resolvedId) {
      this.dispatchEvent(new ShowToastEvent({
        title: 'Add to cart error',
        message: 'The position has not itemId.',
        variant: 'error'
      }));
      return;
    }

    const name = d.name ?? d.item?.Name ?? 'Item';
    const price = typeof d.price === 'string' ? Number(d.price.replace(',', '.')) : Number(d.price) || 0;

    const line = this.cart.find(l => l.itemId === resolvedId);
    if (line) {
      line.amount += 1;
      this.cart = [...this.cart];
    } else {
      this.cart = [...this.cart, { itemId: resolvedId, name, amount: 1, unitCost: price }];
    }

    console.log('cart after add =', this.cart);
    this.dispatchEvent(new ShowToastEvent({ title: 'Added', message: 'Item added to cart', variant: 'success' }));
  }


  openCart(){ this.isCartOpen = true; }
  closeCart(){ this.isCartOpen = false; }


 async handleCheckout(event){
   const src = event?.detail?.lines?.length ? event.detail.lines : this.cart;

   const lines = (src||[])
     .map(l => ({
       itemId  : l.itemId || l.Id || l.id || l.item?.Id,
       amount  : parseInt(l.amount, 10) || 0,
       unitCost: (typeof l.unitCost === 'string'
                 ? Number(l.unitCost.replace(',', '.'))
                 : Number(l.unitCost)) || 0
     }))
     .filter(x => !!x.itemId);

   if (!this.accountId){
     this.dispatchEvent(new ShowToastEvent({ title: 'No Account', message: 'Open the tool from an Account.', variant: 'warning' }));
     return;
   }
   if (!lines.length){
     this.dispatchEvent(new ShowToastEvent({ title: 'Checkout error', message: 'Please choose some items.', variant: 'error' }));
     return;
   }

   const payload = { accountId: this.accountId, lines };
   console.log('checkout payload SNAPSHOT =', JSON.stringify(payload));

   try {
     const purchaseId = await createPurchase({
             accountId: this.accountId,
             lines: lines
         });
     console.log('createPurchase -> purchaseId =', purchaseId);




     this.isCartOpen = false;
     this.cart = [];

     await this.goToPurchase(purchaseId);

   } catch(e){
     console.error('checkout error', e);
     this.dispatchEvent(new ShowToastEvent({
       title: 'Checkout error',
       message: e?.body?.message || e?.message || 'Unknown error',
       variant: 'error'
     }));
   }
 }


 async goToPurchase(purchaseId){
   const pageRef = {
     type: 'standard__recordPage',
     attributes: { recordId: purchaseId, objectApiName: 'Purchase__c', actionName: 'view' }
   };

   try {

     this[NavigationMixin.Navigate](pageRef);
   } catch (navErr) {
     console.warn('Navigate failed, will GenerateUrl + open', navErr);
     try {

       const url = await this[NavigationMixin.GenerateUrl](pageRef);
       if (url) {
         window.open(url, '_self');
         return;
       }
     } catch (genErr) {
       console.error('GenerateUrl failed', genErr);
     }

     this.dispatchEvent(new ShowToastEvent({
       title: 'Purchase created',
       message: `ID: ${purchaseId}. .`,
       variant: 'success'
     }));
   }
 }



  closeCreateItem(){ this.isCreateOpen = false; }

  handleItemCreated(e){
    this.isCreateOpen = false;
    try {
      this.dispatchEvent(new ShowToastEvent({ title: 'Item created', message: e?.detail?.id, variant: 'success' }));
    } catch {}
    this.doSearch();
  }
}


