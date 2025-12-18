<template>
  <v-row :id="ref" class="wrap">
    <!-- FORM-BASE TOP SLOT -->
    <slot :name="getFormTopSlot()" />

    <template v-for="(obj, index) in flatCombinedArraySorted" :key="index">
      <!-- Tooltip Wrapper -->
      <v-tooltip
        :disabled="!obj.schema.tooltip"
        v-bind="getShorthandTooltip(obj.schema.tooltip)"
      >
        <template #activator="{ props }">
          <v-col
            v-show="!obj.schema.hidden"
            :key="index"
            :class="getClassName(obj)"
            v-bind="props"
          >
            <!-- slot on top of type  -> <div slot="slot-bottom-type-[propertyName]"> -->
            <slot :name="getTypeTopSlot(obj)" />
            <!-- slot on top of key  -> <v-btn slot="slot-bottom-key-[propertyName]"> -->
            <slot :name="getKeyTopSlot(obj)" />

            <!-- slot replaces complete item of defined TYPE -> <v-btn slot="slot-item-type-[propertyName]">-->
            <slot :name="getTypeItemSlot(obj)">
              <!-- slot replaces complete item of defined KEY -> <div slot="slot-item-key-[propertyName]">-->
              <slot :name="getKeyItemSlot(obj)">
                <!-- radio -->
                <v-radio-group
                  v-if="obj.schema.type === 'radio'"
                  :model-value="setValue(obj)"
                  :label="obj.schema.label"
                  :color="obj.schema.color || 'primary'"
                  :row="obj.schema.row !== false"
                  :column="obj.schema.column"
                  :disabled="obj.schema.disabled"
                  :readonly="obj.schema.readonly"
                  :hint="obj.schema.hint"
                  :persistent-hint="obj.schema.persistentHint"
                  :error="obj.schema.error"
                  :error-messages="obj.schema.errorMessages"
                  :rules="obj.schema.rules"
                  :class="obj.schema.class"
                  :data-qa="obj.schema['data-qa']"
                  :mandatory="obj.schema.mandatory"
                  :hide-details="obj.schema.hideDetails"
                  @update:modelValue="onInput($event, obj)"
                  inline
                >
                  <v-radio
                    v-for="(option, ix) in obj.schema.options"
                    :key="`${obj.key}-radio-${ix}-${option.value}`"
                    :label="sanitizeOptions(option).label"
                    :value="sanitizeOptions(option).value"
                    :color="obj.schema.color || 'primary'"
                    :disabled="obj.schema.disabled || sanitizeOptions(option).disabled"
                    :ripple="obj.schema.ripple !== false"
                  />
                </v-radio-group>

                <!-- array -->
                <template v-else-if="obj.schema.type === 'array'">
                  <div
                    v-for="(item, idx) in setValue(obj)"
                    :key="idx"
                    v-bind="obj.schema"
                    :value="setValue(obj)"
                  >
                    <slot :name="getKeyArraySlot(obj)" :item="item">
                      <v-form-base
                        :id="`${id}-${obj.key}-${idx}`"
                        :value="item"
                        :schema="obj.schema.schema"
                        :class="`${id}-${obj.key}`"
                      />
                    </slot>
                  </div>
                </template>

                <!-- select -->
                <v-select
                  v-else-if="obj.schema.type === 'select'"
                  :model-value="setValue(obj)"
                  v-bind="obj.schema"
                  :item-title="obj.schema['item-title'] || itemTitle"
                  :item-value="obj.schema['item-value'] || itemValue"
                  @focus="onEvent($event, obj)"
                  @update:modelValue="onInput($event, obj)"
                  @blur="onEvent($event, obj)"
                >    
                <!-- Dynamic slots -->
                <template
                  v-for="slot in Object.keys(obj.schema.slots || {})"
                  #[slot]="data"
                  v-if="obj.schema.enableSlots && obj.schema.slots"
                >
                  <slot :name="obj.schema.slots[slot].name" v-bind="data" :schema="obj.schema"></slot>
                </template>
                <!-- Prepend item slot -->
                <template
                  #prepend-item
                  v-if="obj.schema.enableSlots && obj.schema.slots && obj.schema.slots['prepend-item']"
                >
                  <slot :name="obj.schema.slots['prepend-item'].name" :schema="obj.schema"></slot>
                </template>
                </v-select>

                <!-- treeview -->
                <v-treeview
                  v-else-if="obj.schema.type === treeview"
                  v-model="obj.schema.model"
                  :items="setValue(obj)"
                  :active.sync="obj.schema.model"
                  :open.sync="obj.schema.open"
                  v-bind="obj.schema"
                  @update:open="onEvent({ type: 'click' }, obj, 'open')"
                  @update:active="onEvent({ type: 'click' }, obj, 'selected')"
                />

                <!-- Calendar -->
                <v-menu
                  v-else-if="obj.schema.type === 'calendar'"
                  v-model="obj.isDisplay"
                  :close-on-content-click="false"
                  offset-y
                  full-width
                  ref="menu1"
                  max-width="290px"
                  min-width="290px"
                  transition="scale-transition"
                  :content-class="obj.schema.menuContentClass"
                >
                  <template #activator="{ props }">
                    <v-text-field
                      :model-value="obj.value"
                      v-maska
                      data-maska="['DD-MM-YYYY']"
                      v-bind="{ ...obj.schema, ...props }"
                      @update:modelValue="onDirectDateInput($event, obj)"
                      @blur="validateAndFormatDate($event, obj)"
                      @keyup.enter="validateAndFormatDate($event, obj)"
                      :id="obj.schema.id"
                      :error-messages="obj.dateError"
                      placeholder="DD-MM-YYYY"
                      :append-inner-icon="'mdi-calendar'"
                      @click:append-inner="obj.isDisplay = !obj.isDisplay"
                    />
                  </template>
                  <v-date-picker
                    :model-value="obj.value ? formatDate(obj.value) : datePic"
                    :locale="obj.schema.locale ? obj.schema.locale : 'en-GB'"
                    :min="obj.schema.min"
                    :max="obj.schema.max"
                    @update:modelValue="(val) => { setValueDate(val, obj); obj.isDisplay = false; }"
                    :show-current="true"
                    :no-title="true"
                    :required="true"
                  />
                </v-menu>

                <!-- Timepicker -->
                <v-menu
                  v-else-if="obj.schema.type === 'timepicker'"
                  v-model="obj.isDisplay"
                  :close-on-content-click="false"
                  :return-value.sync="time"
                  offset-y
                  full-width
                  ref="menu1"
                  max-width="290px"
                  min-width="290px"
                  transition="scale-transition"
                >
                  <template #activator="{ props }">
                    <v-text-field
                      :value="obj.value"
                      v-maska="obj.schema.mask"
                      v-bind="{...obj.schema, ...props}"
                      @input="onInput($event, obj)"
                      @change="onInput($event, obj)"
                      :id="obj.schema.id"
                    ></v-text-field>
                  </template>
                  <v-time-picker
                    :value="obj.value"
                    :format="obj.schema.format"
                    @focus="onEvent($event, obj)"
                    @change="onInput($event, obj)"
                  ></v-time-picker>
                </v-menu>

                <!-- list -->
                <template v-else-if="obj.schema.type === list">
                  <v-toolbar v-if="obj.schema.label" v-bind="obj.schema" dark>
                    <v-toolbar-title>{{ obj.schema.label }}</v-toolbar-title>
                  </v-toolbar>
                  <v-list>
                    <v-list-group
                      v-for="(item, ix) in setValue(obj)"
                      :key="ix"
                      :value="obj.schema.model === item"
                      @click="onEvent($event, obj, list)"
                    >
                    <template #activator>
                      <v-list-item>
                        <template #prepend>
                          <v-icon>{{ obj.schema.icon }}</v-icon>
                        </template>
                        <v-list-item-title>
                          {{ obj.schema.item ? item[obj.schema.item] : item }}
                        </v-list-item-title>
                      </v-list-item>
                    </template>
                    </v-list-group>
                  </v-list>
                </template>

                <!-- checkbox | switch -->
                <component
                  :is="mapTypeToComponent(obj.schema.type)"
                  v-else-if="
                    obj.schema.type === 'switch' ||
                      obj.schema.type === 'checkbox'
                  "
                  :model-value="setValue(obj)"
                  v-bind="obj.schema"
                  @update:modelValue="onInput($event, obj)"
                ></component>

                <!-- file -->
                <v-file-input
                  v-else-if="obj.schema.type === 'file'"
                  :model-value="setValue(obj)"
                  v-bind="obj.schema"
                  @focus="onEvent($event, obj)"
                  @blur="onEvent($event, obj)"
                  @update:modelValue="onInput($event, obj)"
                />

                <!-- icon -->
                <v-icon
                  v-else-if="obj.schema.type === 'icon'"
                  v-bind="obj.schema"
                  @click="onEvent($event, obj)"
                >
                  {{ setValue(obj) }}
                </v-icon>

                <!-- btn-toggle -->
                <v-btn-toggle
                  v-else-if="obj.schema.type === 'btn-toggle'"
                  v-bind="obj.schema"
                  color=""
                  :value="setValue(obj)"
                  @change="onInput($event, obj)"
                >
                  <v-btn
                    v-for="(b, ix) in obj.schema.options"
                    :key="ix"
                    v-bind="obj.schema"
                    :value="sanitizeOptions(b).value"
                  >
                    <v-icon :dark="obj.schema.dark">
                      {{ sanitizeOptions(b).icon }}
                    </v-icon>
                    {{ sanitizeOptions(b).label }}
                  </v-btn>
                </v-btn-toggle>

                <!-- btn   -->
                <v-btn
                  v-else-if="obj.schema.type === 'btn'"
                  :small="obj.schema.small"
                  :rounded="obj.schema.rounded"
                  :disabled="obj.schema.disabled"
                  :outlined="obj.schema.outlined"
                  :color="obj.schema.color"
                  :dark="obj.schema.dark"
                  @click.prevent.stop="onEvent($event, obj)"

                >
                  <v-icon
                    v-if="obj.schema.iconLeft"
                    left
                    :dark="obj.schema.dark"
                  >
                    {{ obj.schema.iconLeft }}
                  </v-icon>
                  {{ setValue(obj) }}
                  <v-icon v-if="obj.schema.iconCenter" :dark="obj.schema.dark">
                    {{ obj.schema.iconCenter }}
                  </v-icon>
                  <v-label class="text-capitalize">{{ obj.schema.label }}</v-label>
                  <v-icon
                    v-if="obj.schema.iconRight"
                    right
                    :dark="obj.schema.dark"
                  >
                    {{ obj.schema.iconRight }}
                  </v-icon>
                </v-btn>

                <v-text-field
                  v-else-if="obj.schema.type === 'password'"
                  v-bind="obj.schema"
                  :type="obj.passwordVisible ? 'text' : 'password'"
                  :append-inner-icon="obj.passwordVisible ? 'mdi-eye' : 'mdi-eye-off'"
                  :model-value="setValue(obj)"
                  @focus="onEvent($event, obj)"
                  @blur="onEvent($event, obj)"
                  @click:append-inner="togglePasswordVisibility(obj)"
                  @click:append-outer="onEvent($event, obj, appendOuter)"
                  @click:clear="onEvent($event, obj, clear)"
                  @click:prepend="onEvent($event, obj, prepend)"
                  @click:prepend-inner="onEvent($event, obj, prependInner)"
                  @update:model-value="onInput($event, obj)"
                />

                <!-- only masked v-text-field use this Section - https://vuejs-tips.github.io/vue-the-mask/  -->
                <v-text-field
                  v-else-if="obj.schema.mask"
                  v-maska="obj.schema.mask"
                  v-bind="obj.schema"
                  :value="setValue(obj)"
                  @focus="onEvent($event, obj)"
                  @blur="onEvent($event, obj)"
                  @click:append="onEvent($event, obj, append)"
                  @click:append-outer="onEvent($event, obj, appendOuter)"
                  @click:clear="onEvent($event, obj, clear)"
                  @click:prepend="onEvent($event, obj, prepend)"
                  @click:prepend-inner="onEvent($event, obj, prependInner)"
                  @update:modelValue="onInput($event, obj)"
                />

                <!-- all other Types - see typeToComponent -->
                <component
                  :is="mapTypeToComponent(obj.schema.type)"
                  v-else
                  v-bind="obj.schema"
                  :model-value="setValue(obj)"
                  @focus="onEvent($event, obj)"
                  @blur="onEvent($event, obj)"
                  :item-title="obj.schema['item-text'] || itemTitle"
                  :item-value="obj.schema['item-value'] || itemValue"
                  @click:append="onEvent($event, obj, append)"
                  @click:append-outer="onEvent($event, obj, appendOuter)"
                  @click:clear="onEvent($event, obj, clear)"
                  @click:prepend="onEvent($event, obj, prepend)"
                  @click:prepend-inner="onEvent($event, obj, prependInner)"
                  @update:modelValue="onInput($event, obj)"
                ></component>
              </slot>
            </slot>

            <!-- slot at bottom of item  -> <div slot="slot-bottom-key-[deep-nested-key-name]"> -->
            <slot :name="getTypeBottomSlot(obj)" />
            <slot :name="getKeyBottomSlot(obj)" />
          </v-col>

          <!-- schema.spacer:true - push next item to the right and fill space between items -->
          <v-spacer v-if="obj.schema.spacer" :key="`s-${index}`" />
        </template>
        <!-- slot for tooltip - inspect css.vue for details -->
        <slot name="slot-tooltip" :obj="obj">
          <span>{{ getShorthandTooltipLabel(obj.schema.tooltip) }}</span>
        </slot>
      </v-tooltip>
    </template>
    <!-- FORM-BASE BOTTOM SLOT -->
    <slot :name="getFormBottomSlot()" />
  </v-row>
</template>

<script>
// import & declarations
import {
  get,
  isPlainObject,
  isFunction,
  isString,
  isEmpty,
  orderBy,
  delay
} from 'lodash'
import { vMaska } from "maska/vue"
import moment from 'moment'

const typeToComponent = {
  // map schema.type to type in v-text-field  - https://www.wufoo.com/html5/
  text: 'v-text-field',
  password: 'v-text-field',
  email: 'v-text-field',
  tel: 'v-text-field',
  url: 'v-text-field',
  search: 'v-text-field',
  number: 'v-text-field',
  // use Input Type instead of Picker
  // date: 'v-text-field',
  // time: 'v-text-field',
  // color: 'v-text-field',

  // map schema.type to vuetify-control (vuetify 2.0)
  range: 'v-slider',
  file: 'v-file-input',
  switch: 'v-switch',
  checkbox: 'v-checkbox',
  color: 'v-color-picker',
  date: 'v-date-picker',
  time: 'v-time-picker',
  textarea: 'v-textarea',
  calendar: 'v-date-input'
}
// Declaration
// Declaration
const orderDirection = 'ASC'
const pathDelimiter = '.'
const classKeyDelimiter = '-'
const defaultID = 'form-base'

const onEventDelay = 10 // ms
const mouse = 'mouseenter|mouseleave'
const change = 'input|click' // event change collects events 'input|click'
const watch = 'focus|input|click|blur' // event watch collects events 'focus|input|click|blur'
const display = 'resize|swipe|intersect' // event watch collects events 'resize|swipe|intersect'

const itemClassAppendix = 'item'
const typeClassAppendix = 'type'
const keyClassAppendix = 'key'
const propertyClassAppendix = 'prop'

const arraySlotAppendix = 'slot-array'
const topSlotAppendix = 'slot-top'
const itemSlotAppendix = 'slot-item'
const bottomSlotAppendix = 'slot-bottom'

const clear = 'clear'
const button = 'button'
const treeview = 'treeview'
const list = 'list'
const append = 'append'
const appendOuter = 'append-outer'
const prepend = 'prepend'
const prependInner = 'prepend-inner'

// Mapper for Autogeneration of Schema from Value
const defaultSchemaIfValueIsString = key => ({
  type: 'text',
  label: key,
  flex: { xs: 12, sm: 6, md: 4, lg: 3 }
})
const defaultSchemaIfValueIsNumber = key => ({
  type: 'number',
  label: key,
  flex: { xs: 12, sm: 6, md: 4, lg: 3 }
})
const defaultSchemaIfValueIsBoolean = key => ({
  type: 'checkbox',
  label: key,
  flex: { xs: 12, sm: 6, md: 4, lg: 3 }
})
//
export default {
  name: 'VFormBase',

  // Info Mask https://vuejs-tips.github.io/vue-the-mask/
  directives: {
    maska: vMaska
  },

  props: {
    id: {
      type: String,
      default: defaultID
    },
    value: {
      type: [Object, Array],
      default: () => ({}),
      required: true
    },
    schema: {
      type: [Object, Array],
      default: () => ({}),
      required: true
    }
  },
  data () {
    return {
      flatCombinedArray: [],
      clear,
      button,
      treeview,
      list,
      append,
      appendOuter,
      prepend,
      prependInner,
      itemTitle: 'text',
      itemValue: 'value',
      menu: false,
      date: '',
      datePic: '',
      passwordField: {
        active: 'password',
        options: {
          password: {
            type: 'password',
            icon: 'mdi-eye-off'
          },
          text: {
            type: 'text',
            icon: 'mdi-eye'
          },
        }
      }
    }
  },
  computed: {
    ref () {
      return this.id
    },
    parent () {
      let p = this
      while (p.id.startsWith(p.$parent.$parent.id + '-')) {
        p = p.$parent.$parent
      }
      return p
    },
    index () {
      const m = this.ref && this.ref.match(/\d+$/)
      return m ? Number(m[0]) : 0
    },
    flatCombinedArraySorted () {
      return orderBy(this.flatCombinedArray, ['schema.sort'], [orderDirection])
    },
    storeStateData () {
      return this.value
    },
    storeStateSchema () {
      return this.schema
    }
  },
  watch: {
    value: {
      handler(newVal) {
        this.updateArrayFromState(newVal, this.schema)
      },
      deep: true
    },
    schema: {
      handler(newVal) {
        this.updateArrayFromState(this.value, newVal)
      },
      deep: true
    }
  },
  methods: {
    onDirectDateInput(value, obj) {
      // Clear any previous error
      obj.dateError = null;
      
      // Update the value immediately for user feedback
      obj.value = value;
      
      // If the input is complete (10 characters), validate it
      if (value && value.length === 10) {
        this.validateAndFormatDate({ target: { value } }, obj);
      }
    },

    validateAndFormatDate(event, obj) {
      const inputValue = event.target.value;
      
      if (!inputValue) {
        obj.dateError = null;
        this.onInput(null, obj);
        return;
      }

      // Check if the input matches DD-MM-YYYY format
      const dateRegex = /^(\d{2})-(\d{2})-(\d{4})$/;
      const match = inputValue.match(dateRegex);
      
      if (!match) {
        obj.dateError = 'Please enter date in DD-MM-YYYY format';
        return;
      }

      const [, day, month, year] = match;
      
      // Validate the date using moment
      const isValidDate = moment(`${day}-${month}-${year}`, 'DD-MM-YYYY', true).isValid();
      
      if (!isValidDate) {
        obj.dateError = 'Please enter a valid date';
        return;
      }

      // Check against min/max constraints if they exist
      const inputDate = moment(`${day}-${month}-${year}`, 'DD-MM-YYYY');
      
      if (obj.schema.min) {
        const minDate = moment(obj.schema.min);
        if (inputDate.isBefore(minDate, 'day')) {
          obj.dateError = `Date must be after ${minDate.format('DD-MM-YYYY')}`;
          return;
        }
      }
      
      if (obj.schema.max) {
        const maxDate = moment(obj.schema.max);
        if (inputDate.isAfter(maxDate, 'day')) {
          obj.dateError = `Date must be before ${maxDate.format('DD-MM-YYYY')}`;
          return;
        }
      }

      // Clear error and update value
      obj.dateError = null;
      obj.value = inputValue;
      this.onInput(inputValue, obj);
    },

    formatDate(enteredDate) {
      if (!enteredDate) return null;
      
      const date = new Date(enteredDate);
      const validateDateFormat = moment(enteredDate, 'DD-MM-YYYY', true).isValid();
      
      if (enteredDate && enteredDate.length > 6) {
        if (validateDateFormat) {
          return moment(enteredDate, 'DD-MM-YYYY').format('YYYY-MM-DD');
        }
        // If it's already in YYYY-MM-DD format (from date picker)
        if (moment(enteredDate, 'YYYY-MM-DD', true).isValid()) {
          return enteredDate;
        }
      }
      return null;
    },

    setValueDate(enteredDate, obj) {
      if (!enteredDate) return;
      
      const formattedDate = moment(enteredDate).format('DD-MM-YYYY');
      obj.value = formattedDate;
      obj.dateError = null;
      this.onInput(formattedDate, obj);
    },
    mapTypeToComponent (type) {
      // map ie. schema:{ type:'password', ... } to vuetify control v-text-field'
      return typeToComponent[type] ? typeToComponent[type] : `v-${type}`
    },

    // TOOLTIP
    getShorthandTooltip (schemaTooltip) {
      // check if tooltip is typeof string ->  shorthand { bottom:true, label: obj.schema.tooltip} otherwise take original object
      return isString(schemaTooltip)
        ? { bottom: true, label: schemaTooltip }
        : schemaTooltip
    },
    getShorthandTooltipLabel (schemaTooltip) {
      // check if tooltip is typeof string ->  return Label
      return isString(schemaTooltip)
        ? schemaTooltip
        : schemaTooltip && schemaTooltip.label
    },
    //
    // FORM SLOT
    getFormTopSlot () {
      return this.id + '-top'
    },
    getFormBottomSlot () {
      return this.id + '-bottom'
    },
    //
    // KEY SLOTS
    getKeyArraySlot (obj) {
      // get Key specific name by replacing '.' with '-' and prepending 'slot-item'  -> 'slot-ARRAY-key-address-city'
      return this.getKeyClassNameWithAppendix(obj, arraySlotAppendix + '-key')
    },
    getKeyItemSlot (obj) {
      // get Key specific name by replacing '.' with '-' and prepending 'slot-item'  -> 'slot-item-key-address-city'
      return this.getKeyClassNameWithAppendix(obj, itemSlotAppendix + '-key')
    },
    getKeyTopSlot (obj) {
      // get Key specific name by replacing '.' with '-' and prepending 'slot-top'  -> 'slot-top-key-address-city'
      return this.getKeyClassNameWithAppendix(obj, topSlotAppendix + '-key')
    },
    getKeyBottomSlot (obj) {
      // get Key specific name by replacing '.' with '-' and prepending 'slot-bottom'  -> 'slot-bottom-key-address-city'
      return this.getKeyClassNameWithAppendix(obj, bottomSlotAppendix + '-key')
    },
    //
    // TYPE SLOTS
    getTypeItemSlot (obj) {
      // get Type specific slot name  -> 'slot-item-type-radio'
      return this.getTypeClassNameWithAppendix(obj, itemSlotAppendix + '-type')
    },
    getTypeTopSlot (obj) {
      // get Type specific slot name  -> 'slot-top-type-radio'
      return this.getTypeClassNameWithAppendix(obj, topSlotAppendix + '-type')
    },
    getTypeBottomSlot (obj) {
      // get Type specific slot name  -> 'slot-bottom-type-radio'
      return this.getTypeClassNameWithAppendix(
        obj,
        bottomSlotAppendix + '-type'
      )
    },
    //
    // CLASS Names
    getPropertyClassNameWithAppendix (obj, appendix) {
      // get PROP specific name by app-/prepending 'appendix-' and replacing '.' with '-' in nested key path  -> 'controls switch'
      return obj.key
        ? obj.key
            .split(pathDelimiter)
            .map(s => `${appendix ? appendix + classKeyDelimiter : ''}${s}`)
            .join(' ')
        : ''
    },
    getPropertyClassName (obj) {
      return this.getPropertyClassNameWithAppendix(obj, propertyClassAppendix)
    },
    getKeyClassNameWithAppendix (obj, appendix) {
      // get KEY specific name by app-/prepending 'appendix-' and replacing '.' with '-' in nested key path  -> 'top-slot-address-city'
      return `${appendix ? appendix + classKeyDelimiter : ''}${obj.key.replace(
        /\./g,
        '-'
      )}`
    },
    getKeyClassName (obj) {
      return this.getKeyClassNameWithAppendix(obj, keyClassAppendix)
    },
    getTypeClassNameWithAppendix (obj, appendix) {
      // get TYPE specific class name by prepending '-type' -> 'type-checkbox'
      return `${appendix + classKeyDelimiter}${obj.schema.type}`
    },
    getTypeClassName (obj) {
      return this.getTypeClassNameWithAppendix(obj, typeClassAppendix)
    },
    getColGridClassName (obj) {
      // get COL class from schema.col ->  schema:{ col:{ xs:12, md:4  } || col: 4 } // col: 4 -> is shorthand for -> col:{ xs:4 }
      const keysToGridClassName = key =>
        Object.keys(key)
          .map(k => `v-col-${k}-${key[k]}`)
          .join(' ') //  { xs:12, md:6, lg:4  } => 'col-xs-12 col-md-6 col-lg-4'
          
      return obj.schema.flex
        ? isPlainObject(obj.schema.flex)
          ? keysToGridClassName(obj.schema.flex)
          : `v-col-xs-${obj.schema.flex}`
        : ''
    },
    getOffsetGridClassName (obj) {
      // get OFFSET-COL class from schema.offset ->  schema:{ offset:{ xs:12, md:4  } || offset: 4 } // offset: 4 -> is shorthand for -> offset:{ xs:4 }
      const keysToOffsetClassName = key =>
        Object.keys(key)
          .map(k => `offset-${k}-${key[k]}`)
          .join(' ') //  { xs:12, md:6, lg:4  } => 'xs12 md6 lg4'
      return obj.schema.offset
        ? isPlainObject(obj.schema.offset)
          ? keysToOffsetClassName(obj.schema.offset)
          : `offset-xs-${obj.schema.offset}`
        : ''
    },
    getOrderGridClassName (obj) {
      // get ORDER-COL class from schema.order ->  schema:{ order:{ xs:12, md:4  } || order: 4 } // order: 4 -> is shorthand for -> order:{ xs:4 }
      const keysToOrderClassName = key =>
        Object.keys(key)
          .map(k => `order-${k}${key[k]}`)
          .join(' ') //  { xs:12, md:6, lg:4  } => 'xs12 md6 lg4'
      return obj.schema.order
        ? isPlainObject(obj.schema.order)
          ? keysToOrderClassName(obj.schema.order)
          : `order-xs${obj.schema.order}`
        : ''
    },
    getGridClassName (obj) {
      // combine Col, Offset, Order into a classname
      return `${this.getColGridClassName(obj)} ${this.getOffsetGridClassName(
        obj
      )} ${this.getOrderGridClassName(obj)}`
    },
    getClassName (obj) {
      // combines all into a single classname
      // class => ie. 'item type-checkbox key-address-zip prop-adress prop-zip xs12 md6 offset-xs0'
      return `${itemClassAppendix} ${this.getTypeClassName(
        obj
      )} ${this.getKeyClassName(obj)} ${this.getPropertyClassName(
        obj
      )} ${this.getGridClassName(obj)}`
    },
    //
    // Map Values coming FROM Control or going TO Control
    toCtrl (params) {
      // manipulate value going to control, toCtrl-function must return a (modified) value
      // schema:{ name: { type:'text', toCtrl: ( {value} ) value && value.toUpperCase, ... }, ... }
      return isFunction(params.obj.schema.toCtrl)
        ? params.obj.schema.toCtrl(params)
        : params.value
    },
    fromCtrl (params) {
      // manipulate updated value from control, fromCtrl-function must return a (modified) value
      // schema:{ name: { type:'text', fromCtrl: ( {value} ) value && value.toUpperCase, ... }, ... }
      return isFunction(params.obj.schema.fromCtrl)
        ? params.obj.schema.fromCtrl(params)
        : params.value
    },
    //
    // Button-Toggle sanitize item from array schema.options
    sanitizeOptions (option) {
      // Handle string shorthand notation
      if (isString(option)) {
        return { value: option, label: option }
      }
      
      // Handle object with proper type preservation for boolean values
      if (isPlainObject(option)) {
        return {
          label: option.label || String(option.value),
          value: option.value, // Preserve original type (boolean, string, number)
          disabled: option.disabled || false
        }
      }
      
      // Handle primitive values (boolean, number, etc.)
      return {
        label: String(option),
        value: option
      }
    },
    //
    // Set Value
    setValue (obj) {
      const rawValue = obj?.value
      
      // Special handling for radio buttons with boolean values
      if (obj.schema.type === 'radio') {
        // Return null for unselected state
        if (rawValue === null || rawValue === undefined) {
          return null
        }
        
        // For boolean values, ensure strict type matching
        if (typeof rawValue === 'boolean') {
          return rawValue
        }
        
        // Handle string boolean conversion
        if (typeof rawValue === 'string') {
          if (rawValue.toLowerCase() === 'true') return true
          if (rawValue.toLowerCase() === 'false') return false
        }
        
        // Handle numeric boolean conversion
        if (typeof rawValue === 'number') {
          if (rawValue === 1) return true
          if (rawValue === 0) return false
        }
        
        return rawValue
      }
      
      // Use existing toCtrl logic for other types
      return this.toCtrl({
        value: rawValue || '',
        obj,
        data: this.storeStateData,
        schema: this.storeStateSchema
      })
    },
    //
    // Get Value from Input & other Events
    onInput (value, obj) {
      // Apply fromCtrl transformation first
      let processedValue = this.fromCtrl({
        value,
        obj,
        data: this.storeStateData,
        schema: this.storeStateSchema
      })

      // Special handling for radio buttons to preserve boolean types
      if (obj.schema.type === 'radio') {
        // Don't convert boolean false to null for radio buttons
        if (typeof processedValue === 'boolean') {
          // Keep boolean values as-is
        } else {
          // For other radio types, handle empty values
          processedValue = processedValue === '' ? null : processedValue
        }
      } else {
        // For non-radio types, harmonize empty strings to null
        processedValue = processedValue === '' ? null : processedValue
      }

      // Update deep nested prop(key) with value
      this.setObjectByPath(this.storeStateData, obj.key, processedValue)

      // Emit the change event
      this.emitValue('input', {
        on: 'input',
        id: this.ref,
        index: this.index,
        params: { index: this.index, lastValue: obj.value },
        key: obj.key,
        value: processedValue,
        obj,
        data: this.storeStateData,
        schema: this.storeStateSchema
      })
    },
    togglePasswordVisibility (obj) {
      obj.passwordVisible = !obj.passwordVisible
    },
    onEvent (event, obj, tag) {
      delay(() => {
        const text = event && event.srcElement && event.srcElement.innerText
        const model = obj.schema.model
        const open = obj.schema.open
        const index = this.index
        
        this.emitValue(event.type, {
          on: event.type,
          id: this.ref,
          index,
          params: { text, tag, model, open, index },
          key: obj.key,
          value: obj.value,
          obj,
          event,
          data: this.storeStateData,
          schema: this.storeStateSchema,
          parent: this.parent
        }),
          onEventDelay
      })
    },
    onIntersect (entries, observer, obj) {
      const isIntersecting = entries[0].isIntersecting
      const index = this.index
      this.emitValue('intersect', {
        on: 'intersect',
        id: this.ref,
        index,
        key: obj.key,
        value: obj.value,
        obj,
        params: { isIntersecting, entries, observer },
        data: this.storeStateData,
        schema: this.storeStateSchema
      })
    },
    onSwipe (tag, obj) {
      this.emitValue('swipe', {
        on: 'swipe',
        id: this.ref,
        key: obj.key,
        value: obj.value,
        obj,
        params: { tag },
        data: this.storeStateData,
        schema: this.storeStateSchema
      })
    },
    onResize (event) {
      this.emitValue('resize', {
        on: 'resize',
        id: this.ref,
        params: { x: window.innerWidth, y: window.innerHeight },
        event,
        data: this.storeStateData,
        schema: this.storeStateSchema
      })
    },
    //
    // Emit Event Base
    emitValue (emit, val) {
      this.parent.$emit(this.getEventName(emit), val) // listen to specific event only
      if (mouse.indexOf(emit) > -1)
        this.parent.$emit(this.getEventName('mouse'), val) // listen only to input
      if (change.indexOf(emit) > -1)
        this.parent.$emit(this.getEventName('change'), val) // listen only to input|click|
      if (watch.indexOf(emit) > -1)
        this.parent.$emit(this.getEventName('watch'), val) // listen to focus|input|click|blur
      this.parent.$emit(this.getEventName('update'), val) // listen to all events
    },
    getEventName (eventName) {
      return this.parent.id !== defaultID
        ? `${eventName}:${this.parent.id}`
        : eventName
    },
    //
    // PREPARE ARRAYS DATA & SCHEMA
    setObjectByPath (object, path, value) {
      // resolves chained keys (like 'user.address.street') on an object and set the value
      let pathArray = path.split(pathDelimiter)
      pathArray.forEach((p, ix) => {
        if (ix === pathArray.length - 1) {
          // Vue 3: Direct assignment instead of this.$set
          object[p] = value
        } else {
          // Ensure nested objects exist
          if (!object[p] || typeof object[p] !== 'object') {
            object[p] = {}
          }
          object = object[p]
        }
      })
    },
    updateArrayFromState (data, schema) {
      this.flatCombinedArray.forEach(obj => {
        obj.value = get(data, obj.key, null) // get - lodash
        obj.schema = get(schema, obj.key, null) // get - lodash
      })
    },
    sanitizeShorthandType (schema) {
      // check if schema is typeof string ->  shorthand { type: obj } otherwise take original value
      return isString(schema) ? { type: schema } : schema
    },
    flattenObjects (dat, sch) {
      let data = {}
      let schema = {}
      // Organize Formular using Schema not Data
      Object.keys(sch).forEach(i => {
        // convert string type to object
        sch[i] = this.sanitizeShorthandType(sch[i])

        if (
          (!Array.isArray(dat[i]) && dat[i] && typeof dat[i] === 'object') ||
          (Array.isArray(dat[i]) && Array.isArray(sch[i]))
        ) {
          let { data: flatData, schema: flatSchema } = this.flattenObjects(
            dat[i],
            sch[i]
          )
          Object.keys(flatData).forEach(ii => {
            data[i + pathDelimiter + ii] = flatData[ii]
            schema[i + pathDelimiter + ii] = flatSchema[ii]
          })
        } else {
          data[i] = dat[i]
          schema[i] = sch[i]
        }
      })
      return { data, schema }
    },

    combineObjectsToArray ({ data, schema }) {
      let arr = []
      Object.keys(data).forEach(key => {
        if (!isPlainObject(schema[key])) {
          console.warn(
            `From Schema:`,
            schema,
            ` the Prop '${key}' must be a string with value of type { type:[stringvalue] } or a plainobject with at least { type:'text'} definition.  Schema Prop '${key}' will be ignored!`
          )
          return
        }
        // Initialize passwordVisible for password type fields
        const objData = { key, value: data[key], schema: schema[key] }
        if (schema[key].type === 'password') {
          objData.passwordVisible = schema[key].passwordVisible
        }
        arr.push(objData)
      })
      return arr
    },
    flattenAndCombineToArray (data, schema) {
      // flatten nested structure of both objects 'data' & 'schema' ...
      let flattenedObjects = this.flattenObjects(data, schema)
      // ... and combine them to an array
      return this.combineObjectsToArray(flattenedObjects)
    },
    autogenerateSchema (value) {
      // generate a minimal default schema from value
      let schema = JSON.stringify(value)
      schema = JSON.parse(schema, (key, val) => {
        if (typeof val === 'string') return defaultSchemaIfValueIsString(key)
        if (typeof val === 'number') return defaultSchemaIfValueIsNumber(key)
        if (typeof val === 'boolean') return defaultSchemaIfValueIsBoolean(key)
        return val
      })
      // assign root props to avoid manipulating prop: schema
      Object.keys(schema).forEach(key => (this.schema[key] = schema[key]))
    }
  },
  created () {
    // no schema defined - autogenerate primive schema
    if (isEmpty(this.schema)) this.autogenerateSchema(this.value)

    this.flatCombinedArray = this.flattenAndCombineToArray(
      this.storeStateData,
      this.storeStateSchema
    )
  }
}
</script>