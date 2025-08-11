import { LightningElement, api } from 'lwc';
/**
 * ItemTile
 *
 * A small tile/card UI component that displays an item's information
 *
 */
export default class ItemTile extends LightningElement {
  @api item;
  @api canAdd = false;

  showDetails(){
    this.dispatchEvent(new CustomEvent('showdetails', { detail: this.item }));
  }
  add(){
    this.dispatchEvent(new CustomEvent('add', {
      detail: {
        itemId: this.item.Id,
        name: this.item.Name,
        price: this.item.Price__c
      }
    }));
  }
}