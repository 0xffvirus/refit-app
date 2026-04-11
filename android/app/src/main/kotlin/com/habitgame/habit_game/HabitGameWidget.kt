package com.habitgame.habit_game

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

class HabitGameWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            val completed = prefs.getInt("completed_habits", 0)
            val total = prefs.getInt("total_habits", 0)
            val streak = prefs.getInt("max_streak", 0)
            val waterMl = prefs.getInt("water_ml", 0)
            val waterGoal = prefs.getInt("water_goal", 2500)

            views.setTextViewText(R.id.habits_progress, "$completed/$total")
            views.setTextViewText(R.id.streak_text, if (streak > 0) "🔥 $streak" else "")
            views.setTextViewText(R.id.water_progress, "$waterMl مل")
            views.setTextViewText(R.id.water_goal_text, "الهدف: $waterGoal مل")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
