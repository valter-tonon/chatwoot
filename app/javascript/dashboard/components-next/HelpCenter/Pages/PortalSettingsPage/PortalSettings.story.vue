<script setup>
import PortalSettings from './PortalSettings.vue';
</script>

<template>
  <Story title="Pages/HelpCenter/PortalSettings" :layout="{ type: 'single' }">
    <Variant title="Default">
      <div class="w-[1000px] min-h-screen bg-n-background">
        <PortalSettings />
      </div>
    </Variant>
  </Story>
</template>
