# flake8: noqa
config.load_autoconfig()

DUMMY_USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0'
DEFAULT_FONT_FACE = 'VictorMono Nerd Font'
DEFAULT_FONT_SIZE = '13pt'
DEFAULT_FONT_STRING = f'{DEFAULT_FONT_SIZE} {DEFAULT_FONT_FACE}'
JS_CONFIG = 'content.javascript.enabled'
FIVE_MINUTES = 5 * 60 * 1000

MOD_JS_CONFIG_LIST = [
    'file://*', 'chrome://*/*', 'qute://*/*'
]

for js_config_item in MOD_JS_CONFIG_LIST:
    config.set(JS_CONFIG, True, js_config_item)

c.fonts.downloads        = f'{DEFAULT_FONT_STRING}'
c.fonts.hints            = f'bold {DEFAULT_FONT_STRING}'
c.fonts.keyhint          = f'{DEFAULT_FONT_STRING}'
c.fonts.messages.error   = f'{DEFAULT_FONT_STRING}'
c.fonts.messages.info    = f'{DEFAULT_FONT_STRING}'
c.fonts.messages.warning = f'{DEFAULT_FONT_STRING}'
c.fonts.prompts          = f'{DEFAULT_FONT_STRING}, {DEFAULT_FONT_SIZE} sans-serif'
c.fonts.statusbar        = f'{DEFAULT_FONT_STRING}'

c.downloads.location.directory = '~/downloads'
c.downloads.location.prompt = False

c.url.default_page = "https://www.ecosia.org"
c.url.start_pages  = "https://www.ecosia.org"

c.qt.highdpi = True

c.url.searchengines = {
    "DEFAULT": "https://www.ecosia.org/search?q={}",
    "alt": "https://alternativeto.net/browse/search?q={}",
    "aur": "https://aur.archlinux.org/packages/?O=0&K={}",
    "ddg": "https://duckduckgo.com/?q={}",
    "eco": "https://www.ecosia.org/search?q={}",
    "ggl": "https://encrypted.google.com/search?q={}",
    "hub": "https://github.com/search?q={}",
    "wkp": "https://en.wikipedia.org/w/index.php?title=Special:Search&search={}",
    "ytb": "https://www.youtube.com/results?search_query={}",
}

c.scrolling.bar = 'always'

c.auto_save.interval= FIVE_MINUTES
c.auto_save.session = True

# config.set(
#     'content.headers.user_agent',
#     DUMMY_USER_AGENT,
#     'https://accounts.google.com/*'
# )
