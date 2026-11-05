/* Entry point. Styles first, then the content/app scripts (they attach to window and run
   in this order), then the cinematic engine. */
import "../css/site.css";
import "../css/books.css";
import "../css/tools-extra.css";
import "../css/tools-logs.css";
import "../css/tools-calc.css";
import "../css/tools-plans.css";
import "../css/library.css";
import "../css/assistant.css";
import "../css/book.css";
import "../css/share.css";
import "./styles/tailwind.css";
import "./styles/cinema.css";

import { boot } from "./cinema/index.js";
boot(); // defines window.MOTION before the app renders its first route

import "../js/i18n.js";
import "../js/content.js";
import "../js/app.js";
import "../js/tools.js";
import "../js/tools-extra.js";
import "../js/tools-logs.js";
import "../js/tools-calc.js";
import "../js/tools-plans.js";
import "./tools/practical-labels.js";
import "./tools/practical-calc.js";
import "./pages/library.js";
import "./pages/assistant.js";
import "./pages/book.js";
import "./pages/share.js";
