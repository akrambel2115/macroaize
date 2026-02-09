package com.macroaize.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent
import android.view.View

class StreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_streak).apply {
                // Open App on Click
                val intent = Intent(context, MainActivity::class.java)
                intent.action = Intent.ACTION_MAIN
                intent.addCategory(Intent.CATEGORY_LAUNCHER)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                // Update Data
                val streakCount = widgetData.getInt("streak_count", 0)
                // val disciplineScore = widgetData.getFloat("discipline_score", 0.0f)
                val isActiveToday = widgetData.getBoolean("is_active_today", false)

                setTextViewText(R.id.widget_streak_count, "$streakCount")
                
                // Color logic? 
                // We can't easily do gradients in RemoteViews without drawing to bitmap or shape drawables.
                // For now, let's just create a basic version.
                // Ideally, we'd change the icon tint if active.
                
                // If we want to change icon color:
                // setInt(R.id.widget_flame_icon, "setColorFilter", Color.parseColor("#FF5722"))
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
