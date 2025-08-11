import { LightningElement, api } from 'lwc';
export default class CartModal extends LightningElement {
    @api lines = [];
    get rows(){
        return (this.lines||[]).map(l => ({
        ... l,
        name : l.name,
        lineTotal: (l.unitCost||0) * (l.amount||0) }));
    }
    columns = [
        { label: 'Item Name', fieldName: 'name', type: 'text'},
        { label: 'Unit Cost', fieldName: 'unitCost', type: 'currency' },
        { label: 'Amount', fieldName: 'amount', type: 'number' },
        { label: 'Grand Cost Total', fieldName: 'lineTotal', type: 'currency' }
    ];
    close(){ this.dispatchEvent(new CustomEvent('close')); }
    checkout(){ this.dispatchEvent(new CustomEvent('checkout')); }
}