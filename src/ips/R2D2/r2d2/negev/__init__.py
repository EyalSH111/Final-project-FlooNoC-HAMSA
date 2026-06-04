import r2d2


class Negev(r2d2.R2D2):
    def __init__(self, preset='uart'):
        if preset == 'fspiOverUart':
            r2d2.R2D2.__init__(self, 'fspi', 'uart', 'auto', 115200)
        if preset == 'uart':
            r2d2.R2D2.__init__(self, 'uart', 'uart', 'auto', 115200)
