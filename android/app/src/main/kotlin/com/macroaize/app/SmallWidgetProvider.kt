package com.macroaize.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent



class SmallWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_small).apply {
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
                setOnClickPendingIntent(R.id.widget_log_button, pendingIntent)

                // Update Data
                val calories = widgetData.getInt("calories", 0)
                val goal = widgetData.getInt("goal", 2000)
                val progress = widgetData.getInt("progress", 0)
                
                val caloriesLeft = goal - calories
                val displayCalories = if (caloriesLeft < 0) 0 else caloriesLeft

                setTextViewText(R.id.widget_calories_text, "$displayCalories")
                setProgressBar(R.id.widget_progress_bar, 100, progress, false)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
