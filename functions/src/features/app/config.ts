import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import {
    getScanLimitCfg, getChatLimitCfg, getSubscriptionsEnabled,
    getTermsLink, getPrivacyLink,
    getShareUrlAndroid, getShareUrlIos, getPremiumMonthlyDzd,
    getPremiumYearlyDzd, getSuccessUrl, getFailureUrl,
    getMinRequiredAppVersion, getUpdateMessage
} from '../../remote_config_service';
import { getAiModel, getAndroidIapIds, getIosIapIds } from '../../config';

export const getAppConfig = onCall({ region: 'europe-west1' }, async (_request: CallableRequest) => {
    const config = {
        aiModel: getAiModel(),
        limits: {
            scan: getScanLimitCfg(),
            chat: getChatLimitCfg()
        },
        features: {
            subscriptionsEnabled: getSubscriptionsEnabled()
        },
        iap: {
            android: getAndroidIapIds(),
            ios: getIosIapIds()
        },
        links: {
            terms: getTermsLink(),
            privacy: getPrivacyLink(),
            shareAndroid: getShareUrlAndroid(),
            shareIos: getShareUrlIos(),
            playStoreUrl: getShareUrlAndroid(),
            appStoreUrl: getShareUrlIos()
        },
        pricing: {
            monthlyDzd: getPremiumMonthlyDzd(),
            yearlyDzd: getPremiumYearlyDzd()
        },
        payments: {
            successUrl: getSuccessUrl(),
            failureUrl: getFailureUrl()
        },
        app: {
            minRequiredVersion: getMinRequiredAppVersion(),
            updateMessage: getUpdateMessage()
        }
    };

    return {
        config,
        updatedAt: Date.now(),
        configVersion: '1.0',
        serverTimestamp: admin.firestore.Timestamp.now()
    };
});
