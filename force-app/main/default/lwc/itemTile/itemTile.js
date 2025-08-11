import { LightningElement, api } from 'lwc';
export default class ItemTile extends LightningElement {
    @api item;
    @api canAdd = false;
    showDetails(){ this.dispatchEvent(new CustomEvent('showdetails', { detail: this.item })); }
    add(){ this.dispatchEvent(new CustomEvent('add', { detail: { id: this.item.Id, name : this.item.Name, price: this.item.Price__c }})); }
}