import DetailPage from '@/views/DetailPage.vue'
import Main from '@/views/Main.vue'
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes: [
        { path: '/', name: 'homepage', component: Main },
        { path: '/anime/:id', name: 'detail=page', component: DetailPage }
    ]
})

export default router