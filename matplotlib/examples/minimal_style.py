from pathlib import Path

import matplotlib.pyplot as plt


style_path = Path(__file__).resolve().parents[1] / 'stylelib' / 'my_setting.mplstyle'
plt.style.use(style_path)

fig, ax = plt.subplots()
ax.plot([0, 1, 2, 3], [0, 1, 4, 9], label='sample')
ax.set_xlabel('x')
ax.set_ylabel('y')
ax.legend()

fig.savefig(Path(__file__).with_suffix('.png'))
