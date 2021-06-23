from forbiddenfruit import curse
from typing import Text


def mockey_patch_formatting():
    from datetime import date

    original_strftime = date.strftime

    patterns = {
        "%-d": lambda d: str(d.day),
    }

    def _date_strftime_patch(self: date, fmt: Text) -> str:
        for pattern, get_value in patterns.items():
            if pattern in fmt:
                fmt = fmt.replace(pattern, get_value(self))

        result = original_strftime(self, fmt)
        return result

    curse(date, "strftime", _date_strftime_patch)
