---
layout: home
---

<div class="gallery-wrap" id="gallery" markdown="0">

  <div class="swiper">
    <div class="swiper-lazy-preloader swiper-lazy-preloader-white"></div>
    <div class="swiper-wrapper">

      <div class="swiper-slide">
        <div class="slide-title">Vizima castle</div>
        <div class="slide-image-wrap">
          <div class="slider-wrap">
            <img-comparison-slider>
              <img slot="first"  src="https://webspam.github.io/images/vizima-welcome-before-219.jpg" alt="Vizima castle — before" />
              <img slot="second" src="https://webspam.github.io/images/vizima-welcome-after-219.jpg"  alt="Vizima castle — after" />
            </img-comparison-slider>
            <span class="label-before">Before</span>
            <span class="label-after">After</span>
          </div>
          <div class="swiper-button-prev"></div>
          <div class="swiper-button-next"></div>
        </div>
      </div>

      <div class="swiper-slide">
        <div class="slide-title">Vizima stairwell</div>
        <div class="slide-image-wrap">
          <div class="slider-wrap">
            <img-comparison-slider>
              <img slot="first"  src="https://webspam.github.io/images/vizima-stairwell-before-219.jpg" alt="Vizima stairwell — before" />
              <img slot="second" src="https://webspam.github.io/images/vizima-stairwell-after-219.jpg"  alt="Vizima stairwell — after" />
            </img-comparison-slider>
            <span class="label-before">Before</span>
            <span class="label-after">After</span>
          </div>
          <div class="swiper-button-prev"></div>
          <div class="swiper-button-next"></div>
        </div>
      </div>

      <div class="swiper-slide">
        <div class="slide-title">Novigrad gate</div>
        <div class="slide-image-wrap">
          <div class="slider-wrap">
            <img-comparison-slider>
              <img slot="first"  src="https://webspam.github.io/images/novigrad-gate-before-219.jpg" alt="Novigrad gate — before" />
              <img slot="second" src="https://webspam.github.io/images/novigrad-gate-after-219.jpg"  alt="Novigrad gate — after" />
            </img-comparison-slider>
            <span class="label-before">Before</span>
            <span class="label-after">After</span>
          </div>
          <div class="swiper-button-prev"></div>
          <div class="swiper-button-next"></div>
        </div>
      </div>

      <div class="swiper-slide">
        <div class="slide-title">Spikeroog inn</div>
        <div class="slide-image-wrap">
          <div class="slider-wrap">
            <img-comparison-slider>
              <img slot="first"  src="https://webspam.github.io/images/spikeroog-inn-before-219.jpg" alt="Spikeroog inn — before" />
              <img slot="second" src="https://webspam.github.io/images/spikeroog-inn-after-219.jpg"  alt="Spikeroog inn — after" />
            </img-comparison-slider>
            <span class="label-before">Before</span>
            <span class="label-after">After</span>
          </div>
          <div class="swiper-button-prev"></div>
          <div class="swiper-button-next"></div>
        </div>
      </div>

    </div>
  </div>

  <!-- Thumbnail strip -->
  <div class="swiper swiper-thumbs">
    <div class="swiper-wrapper">
      <div class="swiper-slide"><img src="https://webspam.github.io/images/vizima-welcome-after-219.jpg"   alt="Vizima castle" /></div>
      <div class="swiper-slide"><img src="https://webspam.github.io/images/vizima-stairwell-after-219.jpg" alt="Vizima stairwell" /></div>
      <div class="swiper-slide"><img src="https://webspam.github.io/images/novigrad-gate-after-219.jpg"    alt="Novigrad gate" /></div>
      <div class="swiper-slide"><img src="https://webspam.github.io/images/spikeroog-inn-after-219.jpg"    alt="Spikeroog inn" /></div>
    </div>
  </div>

  <div class="gallery-footer">
    <button class="expand-btn" id="expand-btn" aria-expanded="false">
      <i data-lucide="maximize-2"></i>
      Expand
    </button>
  </div>

</div><!-- /.gallery-wrap -->

<script>
  const thumbSwiper = new Swiper('.swiper-thumbs', {
    modules: [Swiper.FreeMode],
    spaceBetween: 8,
    slidesPerView: 'auto',
    freeMode: true,
    watchSlidesProgress: true,
  });

  new Swiper('.swiper:not(.swiper-thumbs)', {
    modules: [Swiper.Navigation, Swiper.Thumbs, Swiper.EffectFade],
    loop: true,
    effect: 'fade',
    fadeEffect: { crossFade: true },
    navigation: {
      nextEl: '.swiper-button-next',
      prevEl: '.swiper-button-prev',
    },
    thumbs: { swiper: thumbSwiper },
    touchStartPreventDefault: false,
    on: {
      touchStart(swiper, event) {
        swiper.allowTouchMove = !event.target.closest('img-comparison-slider');
      },
    },
  });

  lucide.createIcons();

  const gallery = document.getElementById('gallery');
  const expandBtn = document.getElementById('expand-btn');
  function setExpanded(expanded) {
    gallery.classList.toggle('is-expanded', expanded);
    expandBtn.setAttribute('aria-expanded', expanded);
    expandBtn.innerHTML = `<i data-lucide="${expanded ? 'minimize-2' : 'maximize-2'}"></i> ${expanded ? 'Collapse' : 'Expand'}`;
    lucide.createIcons();
  }

  expandBtn.addEventListener('click', () => {
    setExpanded(!gallery.classList.contains('is-expanded'));
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && gallery.classList.contains('is-expanded')) {
      setExpanded(false);
    }
  });
</script>
