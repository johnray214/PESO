<template>
  <div class="layout-wrapper">
    <div v-if="sidebarOpen" class="sidebar-backdrop" @click="sidebarOpen = false"></div>
    <EmployerSidebar :class="{ 'mobile-open': sidebarOpen }" @close-mobile="sidebarOpen = false" />
    <div class="main-area">
      <EmployerTopbar :title="pageTitle" :subtitle="pageSubtitle" @toggle-sidebar="sidebarOpen = !sidebarOpen" />
      <div class="main-content">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, watch } from 'vue'
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
    const sidebarOpen = ref(false)
    
    const pageTitle = computed(() => route.meta.title || 'Dashboard')
    const pageSubtitle = computed(() => route.meta.subtitle || '')

    watch(() => route.path, () => {
      sidebarOpen.value = false
    })

    return {
      sidebarOpen,
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
  position: relative;
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

.sidebar-backdrop {
  display: none;
}

@media (max-width: 768px) {
  .sidebar-backdrop {
    display: block;
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.4);
    backdrop-filter: blur(2px);
    z-index: 999;
  }
}
</style>
