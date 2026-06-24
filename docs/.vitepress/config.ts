import { defineConfig } from "vitepress";

export default defineConfig({
  base: "/LightRewrite/",
  title: "Light Rewrite",
  description: "A different kind of lighting mod for The Witcher 3",
  cleanUrls: true,
  srcExclude: ["CLAUDE.md"],
  themeConfig: {
    nav: [{ text: "Screenshots", link: "/gallery" }],
    socialLinks: [
      { icon: "github", link: "https://github.com/webspam/LightRewrite" },
    ],
  },
  head: [
    ["link", { rel: "preconnect", href: "https://fonts.googleapis.com" }],
    [
      "link",
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: "" },
    ],
    [
      "link",
      {
        rel: "stylesheet",
        href: "https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&family=Questrial:wght@400;500;600&family=Montserrat:wght@400;500;700&display=swap",
      },
    ],
  ],
});
