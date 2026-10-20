# Builds contact sheets from the screenshots written by shoot.mjs.
# usage: python3 contact.py <qaDir> <tag> <theme> [perSheet=12] [cols=6]   (needs Pillow: set PILPATH if installed elsewhere)
import sys, os, glob
sys.path.insert(0, os.environ.get('PILPATH', '/tmp/pylib312'))
from PIL import Image, ImageDraw
qa, tag, theme = sys.argv[1:4]
per = int(sys.argv[4]) if len(sys.argv) > 4 else 12
cols = int(sys.argv[5]) if len(sys.argv) > 5 else 6
files = sorted(glob.glob(os.path.join(qa, f'{tag}_{theme}_*.png')))
if not files:
    sys.exit('no screenshots found')
tw = int(os.environ.get('TW', '300'))
sheets = []
for s in range(0, len(files), per):
    chunk = files[s:s + per]
    ims = [Image.open(f).convert('RGB') for f in chunk]
    th = int(ims[0].size[1] * tw / ims[0].size[0])
    rows = (len(chunk) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * (tw + 8) + 8, rows * (th + 8) + 8), (128, 128, 128))
    d = ImageDraw.Draw(sheet)
    for i, im in enumerate(ims):
        im = im.resize((tw, th), Image.LANCZOS)
        x, y = 8 + (i % cols) * (tw + 8), 8 + (i // cols) * (th + 8)
        sheet.paste(im, (x, y))
        d.text((x + 6, y + 4), os.path.basename(chunk[i]).replace(f'{tag}_{theme}_', '').replace('.png', ''), fill=(255, 0, 255))
    out = os.path.join(qa, f'contact_{tag}_{theme}_{s // per + 1:02d}.png')
    sheet.save(out)
    sheets.append(out)
# one long overview with every screen (small), for a quick look
sm = 150
ims = [Image.open(f).convert('RGB') for f in files]
th = int(ims[0].size[1] * sm / ims[0].size[0])
c2 = 14
rows = (len(ims) + c2 - 1) // c2
big = Image.new('RGB', (c2 * (sm + 4) + 4, rows * (th + 4) + 4), (128, 128, 128))
for i, im in enumerate(ims):
    big.paste(im.resize((sm, th), Image.LANCZOS), (4 + (i % c2) * (sm + 4), 4 + (i // c2) * (th + 4)))
big.save(os.path.join(qa, f'contact_{tag}_{theme}_all.png'))
print('\n'.join(sheets))
