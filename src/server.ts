import { createApp } from './app.js';
import { TodoStore } from './store.js';

const port = Number(process.env.PORT ?? 3000);
const app = createApp(new TodoStore());

app.listen(port, () => {
  console.log(`aity-playground todo API listening on http://localhost:${port}`);
});
