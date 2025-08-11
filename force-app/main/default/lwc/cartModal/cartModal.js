import { LightningElement, api, track } from 'lwc';
export default class CartModal extends LightningElement {
  @api lines = [];
  get rows(){
    return (this.lines||[]).map(l => ({
      ...l,
      lineTotal: (l.unitCost||0) * (l.amount||0)
    }));
  }
  columns = [
    { label: 'Item Id', fieldName: 'itemId', type: 'text' },
    { label: 'Item Name', fieldName: 'name', type: 'text'},
    { label: 'Unit Cost', fieldName: 'unitCost', type: 'currency' },
    { label: 'Amount', fieldName: 'amount', type: 'number' },
    { label: 'Grand Cost Total', fieldName: 'lineTotal', type: 'currency' }
  ];

  @track selectedRowKeys = [];

  handleRowSelection(event) {

      const selected = event.detail.selectedRows || [];
      this.selectedRowKeys = selected.map(r => r.itemId);
    }
  get selectedLines() {
      if (!this.selectedRowKeys?.length) return [];
      const keys = new Set(this.selectedRowKeys);
      return this.rows.filter(r => keys.has(r.itemId));
    }


   close(){
     this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
   }
   checkout(){
      const picked = this.selectedLines.length ? this.selectedLines : this.rows;
      this.dispatchEvent(new CustomEvent('checkout', {
           bubbles: true,
           composed: true,
           detail: { lines: picked }
         }));
   }

}
