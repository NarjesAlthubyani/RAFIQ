import sys
import os
sys.path.append(os.path.abspath("."))

from Backend.services.activity_explorer import bucket_from_minutes

def test_less_than_1h():
    assert bucket_from_minutes(30) == "<1h"

def test_1_to_2h():
    assert bucket_from_minutes(100) == "1-2h"

def test_2_to_3h():
    assert bucket_from_minutes(150) == "2-3h"

def test_more_than_3h():
    assert bucket_from_minutes(200) == "3h+"

def test_none_input():
    assert bucket_from_minutes(None) is None