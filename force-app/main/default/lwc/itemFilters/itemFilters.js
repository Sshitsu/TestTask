import { LightningElement, api } from 'lwc';

export default class ItemFilters extends LightningElement {
    @api itemcount = 0;
    searchText = '';
    typeValue = '';
    familyValue = '';
    typeOptions = [];
    familyOptions = [];

    _filters;
    @api get filters(){ return this._filters; }
    set filters(val){
        this._filters = val;
        if(!val) return;
        this.typeOptions = [{ label: 'All', value: '' }, ...val.Type__c.map(v => ({ label: v, value: v }))];
        this.familyOptions = [{ label: 'All', value: '' }, ...val.Family__c.map(v => ({ label: v, value: v }))];
    }

    onSearchChange(e){ this.searchText = e.target.value; }
    onTypeChange(e){ this.typeValue = e.detail.value; }
    onFamilyChange(e){ this.familyValue = e.detail.value; }


    fireSearch(){
        const payload = {
            searchText: this.searchText,
            types: this.typeValue ? [this.typeValue] : [],
            families: this.familyValue ? [this.familyValue] : []
        };
        this.dispatchEvent(new CustomEvent('dosearch', { detail: payload }));
    }

}