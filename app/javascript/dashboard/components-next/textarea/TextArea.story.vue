<script setup>
import { ref } from 'vue';
import TextArea from './TextArea.vue';

const bio = ref('');
const description = ref('');
</script>

<template>
  <Story title="Components/TextArea" :layout="{ type: 'grid', width: '400' }">
    <Variant title="Default">
      <div class="p-4 bg-n-background">
        <TextArea placeholder="Default TextArea" />
      </div>
    </Variant>

    <Variant title="With Label">
      <div class="p-4 bg-n-background">
        <TextArea label="Description" placeholder="Enter your description" />
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="p-4 bg-n-background">
        <TextArea
          label="Disabled TextArea"
          placeholder="Can't type here"
          disabled
        />
      </div>
    </Variant>

    <Variant title="With Character Count">
      <div class="p-4 bg-n-background">
        <TextArea
          v-model="bio"
          label="Bio"
          placeholder="Tell us about yourself"
          :max-length="100"
          show-character-count
        />
      </div>
    </Variant>

    <Variant title="Custom Max Length">
      <div class="p-4 bg-n-background">
        <TextArea
          v-model="description"
          label="Long Description"
          placeholder="Enter a longer description"
          :max-length="500"
          show-character-count
        />
      </div>
    </Variant>

    <Variant title="Custom TextArea Class">
      <div class="p-4 bg-n-background">
        <TextArea
          label="Custom Style"
          placeholder="Custom textarea class"
          custom-text-area-class="border-n-amber-5 dark:border-n-amber-5"
        />
      </div>
    </Variant>
  </Story>
</template>
