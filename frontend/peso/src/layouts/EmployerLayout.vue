<template>
  <div class="layout-wrapper">
    <EmployerSidebar />
    <div class="main-area">
      <EmployerTopbar :title="pageTitle" :subtitle="pageSubtitle" />
      <div class="main-content">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar from '@/components/EmployerTopbar.vue'

export default {
  name: 'EmployerLayout',
  components: {
    EmployerSidebar,
    EmployerTopbar
  },
  setup() {
    const route = useRoute()
    
    const pageTitle = computed(() => route.meta.title || 'Dashboard')
    const pageSubtitle = computed(() => route.meta.subtitle || '')

    return {
      pageTitle,
      pageSubtitle
    }
  }
}
</script>

<style scoped>
.layout-wrapper { 
  display: flex; 
  height: 100vh; 
  background: transparent; 
  overflow: hidden; 
}
.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background-color: transparent !important;
}
.main-content {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 0;
  display: flex;
  flex-direction: column;
}
</style>
