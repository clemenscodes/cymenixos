{pkgs}: let
  src = pkgs.writeText "speex_noise_suppressor.c" ''
    #include <ladspa.h>
    #include <speex/speex_preprocess.h>
    #include <stdlib.h>

    #define PLUGIN_ID  12001
    #define PORT_IN    0
    #define PORT_OUT   1
    #define PORT_LEVEL 2

    typedef struct {
        unsigned long         rate;
        SpeexPreprocessState *st;
        spx_int16_t          *buf;
        int                   frame_size;
        LADSPA_Data          *in;
        LADSPA_Data          *out;
        LADSPA_Data          *level_db;
    } Plugin;

    static LADSPA_Handle instantiate(const LADSPA_Descriptor *d, unsigned long rate) {
        Plugin *p = calloc(1, sizeof(Plugin));
        if (p) p->rate = rate;
        return p;
    }

    static void connect_port(LADSPA_Handle h, unsigned long port, LADSPA_Data *data) {
        Plugin *p = h;
        switch (port) {
            case PORT_IN:    p->in       = data; break;
            case PORT_OUT:   p->out      = data; break;
            case PORT_LEVEL: p->level_db = data; break;
        }
    }

    static void run(LADSPA_Handle h, unsigned long n) {
        Plugin *p = h;

        /* (re)initialise when frame size changes — PipeWire is consistent at quantum */
        if (p->frame_size != (int)n) {
            if (p->st) speex_preprocess_state_destroy(p->st);
            free(p->buf);
            p->st         = speex_preprocess_state_init((int)n, (int)p->rate);
            p->buf        = malloc(n * sizeof(spx_int16_t));
            p->frame_size = (int)n;
            int v = 1;
            speex_preprocess_ctl(p->st, SPEEX_PREPROCESS_SET_DENOISE, &v);
        }

        /* update suppress level every block (cheap int write) */
        int lvl = p->level_db ? (int)*p->level_db : -15;
        speex_preprocess_ctl(p->st, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &lvl);

        /* float → int16 */
        for (unsigned long i = 0; i < n; i++) {
            float s = p->in[i];
            if (s >  1.f) s =  1.f;
            if (s < -1.f) s = -1.f;
            p->buf[i] = (spx_int16_t)(s * 32767.f);
        }

        speex_preprocess_run(p->st, p->buf);

        /* int16 → float */
        for (unsigned long i = 0; i < n; i++)
            p->out[i] = p->buf[i] * (1.f / 32767.f);
    }

    static void cleanup(LADSPA_Handle h) {
        Plugin *p = h;
        if (p->st) speex_preprocess_state_destroy(p->st);
        free(p->buf);
        free(p);
    }

    static const LADSPA_PortDescriptor port_descs[] = {
        LADSPA_PORT_AUDIO   | LADSPA_PORT_INPUT,
        LADSPA_PORT_AUDIO   | LADSPA_PORT_OUTPUT,
        LADSPA_PORT_CONTROL | LADSPA_PORT_INPUT,
    };
    static const char * const port_names[] = {
        "Input", "Output", "Suppress Level (dB)"
    };
    static const LADSPA_PortRangeHint port_hints[] = {
        {0, 0.f, 0.f},
        {0, 0.f, 0.f},
        {LADSPA_HINT_BOUNDED_BELOW | LADSPA_HINT_BOUNDED_ABOVE | LADSPA_HINT_DEFAULT_MIDDLE,
         -30.f, 0.f},
    };

    static const LADSPA_Descriptor the_desc = {
        PLUGIN_ID,
        "speex_noise_suppressor_mono",
        0,
        "Speex Noise Suppressor Mono",
        "cymenixos",
        "GPL-2.0-only",
        3,
        port_descs,
        port_names,
        port_hints,
        NULL, instantiate, connect_port,
        NULL, run, NULL, NULL, NULL, cleanup
    };

    const LADSPA_Descriptor *ladspa_descriptor(unsigned long i) {
        return i == 0 ? &the_desc : NULL;
    }
  '';
in
  pkgs.stdenv.mkDerivation {
    pname = "speex-noise-suppressor-ladspa";
    version = "1.0.0";

    dontUnpack = true;

    nativeBuildInputs = [pkgs.pkg-config];
    buildInputs = [pkgs.speex pkgs.ladspa-sdk];

    buildPhase = ''
      cp ${src} speex_noise_suppressor.c
      $CC -O2 -fPIC -shared \
        $(pkg-config --cflags speexdsp) \
        -I${pkgs.ladspa-sdk}/include \
        speex_noise_suppressor.c \
        $(pkg-config --libs speexdsp) \
        -o libspeex_noise_suppressor_ladspa.so
    '';

    installPhase = ''
      mkdir -p $out/lib/ladspa
      cp libspeex_noise_suppressor_ladspa.so $out/lib/ladspa/
    '';
  }
