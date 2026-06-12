import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior(_to, _from, savedPosition) {
    if (savedPosition) return savedPosition
    return { top: 0 }
  },
  routes: [
    {
      path: '/',
      name: 'landing',
      component: () => import('@/views/LandingView.vue'),
      meta: { standalone: true },
    },
    {
      path: '/docs',
      name: 'home',
      component: () => import('@/views/HomeView.vue'),
    },
    {
      path: '/architecture',
      name: 'architecture',
      component: () => import('@/views/ArchitectureView.vue'),
    },
    {
      path: '/setup',
      name: 'setup',
      component: () => import('@/views/SetupView.vue'),
    },
    {
      path: '/usage',
      name: 'usage',
      component: () => import('@/views/UsageView.vue'),
    },
    {
      path: '/accessibility',
      name: 'accessibility',
      component: () => import('@/views/AccessibilityView.vue'),
    },
    {
      path: '/development',
      name: 'development',
      component: () => import('@/views/DevelopmentView.vue'),
    },
    {
      path: '/user-guide',
      name: 'userGuide',
      component: () => import('@/views/UserGuideView.vue'),
    },
    {
      path: '/developer-guide',
      name: 'developerGuide',
      component: () => import('@/views/DeveloperGuideView.vue'),
    },
  ],
})

export default router