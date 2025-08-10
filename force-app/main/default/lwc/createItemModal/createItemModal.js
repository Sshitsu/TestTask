import { LightningElement, api } from 'lwc';
import createItem from '@salesforce/apex/ItemController.createItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateItemModal extends LightningElement {
  @api picklistFilters; // { Type__c: [...], Family__c: [...] }

  name = '';
  price = null;
  typeValue = '';
  familyValue = '';
  description = '';
  image = '';
  autoImage = true;

  get typeOptions(){ return [{label:'--', value:''}, ...(this.picklistFilters?.Type__c||[]).map(v=>({label:v,value:v}))]; }
  get familyOptions(){ return [{label:'--', value:''}, ...(this.picklistFilters?.Family__c||[]).map(v=>({label:v,value:v}))]; }

  get isCreateDisabled(){ return !this.name; }

  onName(e){ this.name = e.target.value; }
  onPrice(e){ this.price = e.target.value; }
  onType(e){ this.typeValue = e.detail.value; }
  onFamily(e){ this.familyValue = e.detail.value; }
  onDesc(e){ this.description = e.target.value; }
  onImage(e){ this.image = e.target.value; }
  onAuto(e){ this.autoImage = e.target.checked; }

  close(){ this.dispatchEvent(new CustomEvent('close')); }

  async create(){
    try{
      const rec = {
        sobjectType: 'Item__c',
        Name: this.name,
        Price__c: this.price,
        Type__c: this.typeValue || null,
        Family__c: this.familyValue || null,
        Description__c: this.description || null,
        Image__c: this.image || null
      };
      const id = await createItem({ rec, autoImage: this.autoImage });
      this.dispatchEvent(new ShowToastEvent({ title:'Item created', message:id, variant:'success' }));
      this.dispatchEvent(new CustomEvent('created', { detail: { id } }));
    } catch(e){

      console.error(e);
      this.dispatchEvent(new ShowToastEvent({ title:'Error', message:e?.body?.message || e.message, variant:'error' }));
    }
  }
}
