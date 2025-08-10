import { LightningElement, api } from 'lwc';
import refreshItemImage from '@salesforce/apex/ItemController.refreshItemImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ItemDetailsModal extends LightningElement {
    @api item;
    close(){ this.dispatchEvent(new CustomEvent('close')); }
    async getImage(){
        try{
            const url = await refreshItemImage({ itemId: this.item.Id });
            if(url){
                this.item = { ...this.item, Image__c: url };
                this.dispatchEvent(new ShowToastEvent({title : 'Image update' , message:'Unsplash image set', variant:'success'}))
            }else {
                this.dispatchEvent(new ShowToastEvent({ title:'No image found', message:'Try another name', variant:'warning'}));
            }

        }catch(e){
            console.error(e);
            this.dispatchEvent(new ShowToastEvent({ title:'Error', message:e?.body?.message || e.message, variant:'error'}));
        }
    }
}