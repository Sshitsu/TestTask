import { LightningElement, api, track } from 'lwc';
/**
 * CartModal
 *
 *  Allows selecting specific rows for checkout, Displays a list of cart lines in a table with calculated totals.
 */
export default class CartModal extends LightningElement {
    /**
   * List of cart lines passed in from the parent component.
   * Each line should contain:
   *  { itemId, name, unitCost, amount }
   */
  @api lines = [];
   /**
     * Computed table rows with an extra `lineTotal` field.
     * lineTotal = unitCost * amount (defaulting to 0 if null/undefined)
     */
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

   // If row was selected we add Id to selectedRowKeys
  handleRowSelection(event) {
      const selected = event.detail.selectedRows || [];
      this.selectedRowKeys = selected.map(r => r.itemId);
    }
    // Get all selected rows
  get selectedLines() {
      if (!this.selectedRowKeys?.length) return [];
      const keys = new Set(this.selectedRowKeys);
      return this.rows.filter(r => keys.has(r.itemId));
    }


   close(){
     this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
   }
   checkout(){
      // 0 rows were selected send all rows
      const picked = this.selectedLines.length ? this.selectedLines : this.rows;
      this.dispatchEvent(new CustomEvent('checkout', {
           bubbles: true,
           composed: true,
           detail: { lines: picked }
         }));
   }

}
