<template>
  <v-container>
    <v-row>
      <v-col
        cols="12"
        sm="12"
        md="3"
      >
        <v-card>
          <v-card-text>
            <v-text-field
              v-model="name"
              label="名前"
              type="text"
            />
            <v-text-field
              v-model="message"
              label="メッセージ"
              type="text"
              :rules="[rules.required, rules.message]"
            />
          </v-card-text>
          <v-card-actions>
            <v-btn
              color="primary"
              @click="sendMessage()">
              投稿
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-col>
      <v-col
        cols="12"
        sm="12"
        md="9"
      >
        <v-simple-table>
          <template v-slot:default>
            <thead>
              <tr>
                <th class="text-left">名前</th>
                <th class="text-left">投稿日時</th>
                <th class="text-left">メッセージ</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in comments" :key="item.name">
                <td>{{ item.name || '名無しさん' }}</td>
                <td>{{ dateToString(item._ts) }}</td>
                <td>{{ item.message }}</td>
              </tr>
            </tbody>
          </template>
        </v-simple-table>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
  import { HubConnectionBuilder, LogLevel } from "@microsoft/signalr";
  export default {
    name: 'CommentBoard',
    data: () => ({
      comments: [],
      name: '',
      message: '',
      rules: {
        required: value => !!value || '入力してください。'
      }
    }),
    created: async function() {
      // 今月のデータだけ取得・表示
      const now = new Date();
      const begin = Date.UTC(now.getFullYear(), now.getMonth(), 1) / 1000;
      const end = Date.UTC(now.getFullYear(), now.getMonth() + 1, 1) / 1000;
      const res = await fetch(`/api/getComments/${begin}/${end}`);
      if (res.ok) {
        this.comments = await res.json();
      }
      // SignalR
      const connection = new HubConnectionBuilder()
        .withUrl('/api')
        .configureLogging(LogLevel.Information)
        .build();
      connection.on('newData', async (message) => {
        this.comments.push(message);
      });
      const start = async () => {
        try {
          await connection.start();
          console.log("connected");
        } catch (err) {
          console.log(err);
          setTimeout(() => start(), 5000);
        }
      }
      connection.onclose(async () => {
        await start();
      });
      start();
    },
    methods: {
      dateToString: function(unixtime) {
        const date = new Date(unixtime * 1000);
        return `${date.toLocaleDateString()} ${date.toLocaleTimeString()}`; 
      },
      sendMessage: async function() {
        const data = {
          name: this.name,
          message: this.message
        };
        await fetch('/api/postComment', {
          method: 'POST',
          header: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(data)
        });
        this.message = '';
      }
    }
  }
</script>