<template>
  <v-app>
    <v-app-bar
      app
      color="primary"
      dark
    >
      <div class="d-flex align-center">
        <v-img
          alt="Vuetify Logo"
          class="shrink mr-2"
          contain
          src="https://cdn.vuetifyjs.com/images/logos/vuetify-logo-dark.png"
          transition="scale-transition"
          width="40"
        />
        簡易掲示板アプリ
      </div>
    </v-app-bar>

    <v-main>
      <CommentBoard/>
    </v-main>
  </v-app>
</template>

<script>
import CommentBoard from './components/CommentBoard';

export default {
  name: 'App',

  components: {
    CommentBoard,
  },

  data: () => ({
    //
  }),
};
</script>
