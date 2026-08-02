"""URL 얼개. 앱이 부르는 것은 전부 /api/ 아래에 있다."""

from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('api/', include('ocr.urls')),
    path('admin/', admin.site.urls),
]
