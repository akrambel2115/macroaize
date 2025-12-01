import * as admin from 'firebase-admin';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

dayjs.extend(utc);
dayjs.extend(timezone);

// Convert to Date
export function toDate(dateValue: admin.firestore.Timestamp | string | Date | null | undefined): Date | null {
    if (!dateValue) return null;
    if (dateValue instanceof Date) return dateValue;
    if (typeof dateValue === 'string') return new Date(dateValue);
    if (typeof dateValue === 'object' && 'toDate' in dateValue && typeof dateValue.toDate === 'function') {
        return dateValue.toDate();
    }
    return null;
}

// Convert to Dayjs
export function toDayjs(dateValue: admin.firestore.Timestamp | string | Date | null | undefined): dayjs.Dayjs | null {
    const date = toDate(dateValue);
    return date ? dayjs(date) : null;
}

// Add plan duration
export function addDuration(start: dayjs.Dayjs, planType: string): dayjs.Dayjs {
    return planType === 'yearly' ? start.add(1, 'year') : start.add(1, 'month');
}

// Get current time
export function safeNow(): dayjs.Dayjs {
    return dayjs().utc();
}
