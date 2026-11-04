/* Entry point. Styles first, then the content/app scripts (they attach to window and run
   in this order), then the cinematic engine. */
import "../css/site.css";
import "../css/books.css";
import "../css/tools-extra.css";
import "./styles/tailwind.css";
import "./styles/cinema.css";

import { boot } from "./cinema/index.js";
boot(); // defines window.MOTION before the app renders its first route

import "../js/i18n.js";
import "../js/content.js";
import "../js/app.js";
import "../js/tools.js";
import "../js/tools-extra.js";
