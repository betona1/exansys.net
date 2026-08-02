from django.urls import path

from ocr import views

urlpatterns = [
    path('health', views.health),
    path('jobs', views.create_job),
    path('jobs/<uuid:uuid>', views.job_detail),
    path('jobs/<uuid:uuid>/pages', views.job_pages),
    path('jobs/<uuid:uuid>/cancel', views.cancel_job),
    path('jobs/<uuid:uuid>/resume', views.resume_job),
]
