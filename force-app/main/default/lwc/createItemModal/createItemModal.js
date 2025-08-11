import { LightningElement, api } from 'lwc';
import createItem from '@salesforce/apex/ItemController.createItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateItemModal extends LightningElement {
    @api picklistFilters;

    name = '';
    price = null;
    priceDisplay = '';
    typeValue = '';
    familyValue = '';
    description = '';
    image = '';
    autoImage = true;

    safeToast(payload) {
        try {
            this.dispatchEvent(new ShowToastEvent(payload));
        } catch (err) {
            console.error('ShowToastEvent failed', err, payload);
        }
    }

    get typeOptions() {
        const src = (this.picklistFilters?.Type__c || []);
        return [{ label: '--', value: '' }, ...src.map(v => ({ label: v, value: v }))];
    }

    get familyOptions() {
        const src = (this.picklistFilters?.Family__c || []);
        return [{ label: '--', value: '' }, ...src.map(v => ({ label: v, value: v }))];
    }

    get isCreateDisabled() {
        return !this.name;
    }

    onName(e) {
        this.name = e.target.value;
    }

    onPriceInput(e) {

        this.priceDisplay = e.target.value;
    }

    onPriceBlur(e) {
        const raw = (e.target.value ?? '').toString().trim();
        if (!raw) {
            this.price = null;
            this.priceDisplay = '';
            e.target.setCustomValidity('');
            return;
        }


        const normalized = raw.replace(',', '.');

        const num = Number(normalized);
        if (!Number.isFinite(num)) {
            e.target.setCustomValidity('Введите число, например 123.45');
            e.target.reportValidity();
            return;
        }


        const rounded = Math.round(num * 100) / 100;

        this.price = rounded;
        this.priceDisplay = rounded.toFixed(2);

        e.target.setCustomValidity('');
        e.target.reportValidity();
    }

    onType(e) {
        this.typeValue = e.detail.value;
    }

    onFamily(e) {
        this.familyValue = e.detail.value;
    }

    onDesc(e) {
        this.description = e.target.value;
    }

    onImage(e) {
        this.image = e.target.value;
    }

    onAuto(e) {
        this.autoImage = e.target.checked;
    }

    close() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async create() {
        try {
            const rec = {
                Name: this.name,
                Price__c: Number.isFinite(this.price) ? this.price : null,
                Type__c: this.typeValue || null,
                Family__c: this.familyValue || null,
                Description__c: this.description || null,
                Image__c: this.image || null
            };

            const id = await createItem({ rec, autoImage: this.autoImage });
            const msg = typeof id === 'string' ? `Item created: ${id}` : 'Item created';

            this.safeToast({ title: 'Success', message: msg, variant: 'success' });

            this.dispatchEvent(
                new CustomEvent('created', {
                    detail: { id },
                    bubbles: true,
                    composed: true
                })
            );

        } catch (e) {
            const msg =
                e?.body?.message ||
                e?.body?.pageErrors?.[0]?.message ||
                (e?.body?.fieldErrors && Object.values(e.body.fieldErrors).flat()?.[0]?.message) ||
                e?.message ||
                'Unknown error';

            console.error('createItem failed', e);

            this.safeToast({ title: 'Error', message: String(msg), variant: 'error' });
        }
    }
}
