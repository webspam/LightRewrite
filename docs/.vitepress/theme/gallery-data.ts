// Images live in the webspam.github.io/images repo, not here.

export interface GalleryItem {
  id: string;
  title: string;
  tag?: string;
  before: string;
  after: string;
}

export const NATIVE_SIZE = { w: 3840, h: 1440 };

const IMG = "https://webspam.github.io/images/";

export const GALLERY: GalleryItem[] = [
  {
    id: "spikeroog-inn",
    title: "Spikeroog inn",
    tag: "Interior",
    before: IMG + "spikeroog-inn-before-219.jpg",
    after: IMG + "spikeroog-inn-after-219.jpg",
  },
  {
    id: "sturgeon",
    title: "Golden Sturgeon",
    tag: "Main bar",
    before: IMG + "sturgeon-before-219.jpg",
    after: IMG + "sturgeon-after-219.jpg",
  },
  {
    id: "chameleon",
    title: "The Chameleon",
    tag: "Interior",
    before: IMG + "chameleon-before-219.jpg",
    after: IMG + "chameleon-after-219.jpg",
  },
  {
    id: "skellige-inn",
    title: "Skellige inn",
    tag: "Interior",
    before: IMG + "skellige-inn-before-219.jpg",
    after: IMG + "skellige-inn-after-219.jpg",
  },
  {
    id: "holger-haus",
    title: "Holger haus",
    tag: "Interior",
    before: IMG + "holger-haus-before-219.jpg",
    after: IMG + "holger-haus-after-219.jpg",
  },
  {
    id: "triss-room",
    title: "Triss's room",
    tag: "Interior",
    before: IMG + "triss-room-before-219.jpg",
    after: IMG + "triss-room-after-219.jpg",
  },
  {
    id: "sturgeon-upstairs",
    title: "Golden Sturgeon",
    tag: "Upstairs",
    before: IMG + "sturgeon-upstairs-before-219.jpg",
    after: IMG + "sturgeon-upstairs-after-219.jpg",
  },
  {
    id: "vizima-castle",
    title: "Vizima castle",
    tag: "Interior",
    before: IMG + "vizima-welcome-before-219.jpg",
    after: IMG + "vizima-welcome-after-219.jpg",
  },
  {
    id: "vizima-stairwell",
    title: "Vizima stairwell",
    tag: "Interior",
    before: IMG + "vizima-stairwell-before-219.jpg",
    after: IMG + "vizima-stairwell-after-219.jpg",
  },
  {
    id: "novigrad-gate",
    title: "Novigrad gate",
    tag: "Exterior",
    before: IMG + "novigrad-gate-before-219.jpg",
    after: IMG + "novigrad-gate-after-219.jpg",
  },
  {
    id: "novigrad-bits",
    title: "Novigrad bits",
    tag: "Candlelit interior",
    before: IMG + "novigrad-bits-before-219.jpg",
    after: IMG + "novigrad-bits-after-219.jpg",
  },
];
