<script setup>
import { useAttrs } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const attrs = useAttrs();
const globalConfig = useMapGetter('globalConfig/get');

// Caminho compatível com Vite para assets públicos
const convertoIcon = new URL('/convertoicon.png', import.meta.url).href;
</script>

<template>
  <img
    v-if="globalConfig.logoThumbnail"
    v-bind="attrs"
    :src="globalConfig.logoThumbnail"
  />
  <img
    v-else
    v-bind="attrs"
    :src="convertoIcon"
    alt="Logo Converto Chat"
  />
</template>
