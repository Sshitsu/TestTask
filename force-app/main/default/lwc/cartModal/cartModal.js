import { LightningElement, api } from 'lwc';
export default class CartModal extends LightningElement {
    @api lines = [];
    get rows(){
        return (this.lines||[]).map(l => ({ ...l, lineTotal: (l.unitCost||0) * (l.amount||0) }));
    }
    columns = [
        { label: 'Item', fieldName: 'itemId' },
        { label: 'Unit Cost', fieldName: 'unitCost', type: 'currency' },
        { label: 'Amount', fieldName: 'amount', type: 'number' },
        { label: 'Line Total', fieldName: 'lineTotal', type: 'currency' }
    ];
    close(){ this.dispatchEvent(new CustomEvent('close')); }
    checkout(){ this.dispatchEvent(new CustomEvent('checkout')); }
}