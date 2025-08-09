import { LightningElement, api } from 'lwc';
export default class ItemDetailsModal extends LightningElement {
    @api item;
    close(){ this.dispatchEvent(new CustomEvent('close')); }
}