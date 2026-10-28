package vendor.gree.ims;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import vendor.qti.hardware.radio.ims.V1_0.ClipProvisionStatus;
import vendor.qti.hardware.radio.ims.V1_0.ClirInfo;
import vendor.qti.hardware.radio.ims.V1_0.ColrInfo;
import vendor.qti.hardware.radio.ims.V1_0.ConfigInfo;
import vendor.qti.hardware.radio.ims.V1_0.IImsRadio;
import vendor.qti.hardware.radio.ims.V1_0.IImsRadioIndication;
import vendor.qti.hardware.radio.ims.V1_0.IImsRadioResponse;
import vendor.qti.hardware.radio.ims.V1_0.ImsSubConfigInfo;
import vendor.qti.hardware.radio.ims.V1_0.RegistrationInfo;
import vendor.qti.hardware.radio.ims.V1_0.SipErrorInfo;
import vendor.qti.hardware.radio.ims.V1_0.SuppServiceStatus;

/**
 * V1_0 IImsRadio for imsradio0 and imsradio1. The hash chain stays on the
 * Stub compiled into ims.apk. Registration is whatever IMSA reports.
 * Call control and IMSS writes return REQUEST_NOT_SUPPORTED and are not sent.
 */
public class ImsRadioService extends IImsRadio.Stub {
    private static final int NONE = 0;
    private static final int GENERIC_FAILURE = 2;
    private static final int REQUEST_NOT_SUPPORTED = 6;

    private static final int REGISTERED = 0;
    private static final int NOT_REGISTERED = 1;
    private static final int REGISTERING = 2;
    private static final int INVALID = 3;
    private static final int RADIO_TECH_UNKNOWN = 1;

    private final int slot;
    private IImsRadioResponse response;

    public ImsRadioService(int slot) {
        this.slot = slot;
    }

    public static void main(String[] args) {
        try {
            new ImsRadioService(0).registerAsService("imsradio0");
            new ImsRadioService(1).registerAsService("imsradio1");
            android.util.Log.i("ImsRadioService",
                    "registered imsradio0 and imsradio1, slot0 IMSA status " + queryImsaStatus());
            android.os.HwBinder.joinRpcThreadpool();
        } catch (Throwable t) {
            t.printStackTrace();
            System.exit(1);
        }
    }

    public void setCallback(IImsRadioResponse response, IImsRadioIndication indication) {
        this.response = response;
    }

    public void getImsRegistrationState(int serial) {
        RegistrationInfo info = new RegistrationInfo();
        info.errorCode = 0;
        info.errorMessage = "";
        info.pAssociatedUris = "";
        info.radioTech = RADIO_TECH_UNKNOWN;
        info.state = INVALID;
        int error = GENERIC_FAILURE;
        if (slot == 0) {
            int status = queryImsaStatus();
            if (status >= 0) {
                error = NONE;
                info.state = hidlState(status);
            }
        } else {
            error = NONE;
            info.state = NOT_REGISTERED;
        }
        try {
            if (response != null) response.getRegistrationResponse(serial, error, info);
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void requestRegistrationChange(int serial, int state) {
        unsupported(serial);
    }

    public void setConfig(int serial, ConfigInfo config) {
        try {
            if (response != null) {
                response.setConfigResponse(serial, REQUEST_NOT_SUPPORTED,
                        config != null ? config : emptyConfig());
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void getConfig(int serial, ConfigInfo config) {
        try {
            if (response != null) {
                response.getConfigResponse(serial, REQUEST_NOT_SUPPORTED,
                        config != null ? config : emptyConfig());
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void addParticipant(int serial, vendor.qti.hardware.radio.ims.V1_0.DialRequest dialRequest) {
        pair(serial, "addParticipantResponse");
    }

    public void answer(int serial, int callType, int presentation, int mode) {
        pair(serial, "answerResponse");
    }

    public void cancelModifyCall(int serial, int callId) {
        pair(serial, "cancelModifyCallResponse");
    }

    public void conference(int serial) {
        try {
            if (response != null) {
                response.conferenceResponse(serial, REQUEST_NOT_SUPPORTED, sip());
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void deflectCall(int serial, vendor.qti.hardware.radio.ims.V1_0.DeflectRequestInfo info) {
        pair(serial, "deflectCallResponse");
    }

    public void dial(int serial, vendor.qti.hardware.radio.ims.V1_0.DialRequest dialRequest) {
        pair(serial, "dialResponse");
    }

    public void exitEmergencyCallbackMode(int serial) {
        pair(serial, "exitEmergencyCallbackModeResponse");
    }

    public void explicitCallTransfer(int serial,
            vendor.qti.hardware.radio.ims.V1_0.ExplicitCallTransferInfo info) {
        pair(serial, "explicitCallTransferResponse");
    }

    public void getCallWaiting(int serial, int serviceClass) {
        try {
            if (response != null) {
                response.getCallWaitingResponse(serial, REQUEST_NOT_SUPPORTED, 0, 0, sip());
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void getClip(int serial) {
        try {
            if (response != null) {
                ClipProvisionStatus status = new ClipProvisionStatus();
                status.hasErrorDetails = false;
                status.errorDetails = sip();
                response.getClipResponse(serial, REQUEST_NOT_SUPPORTED, status);
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void getClir(int serial) {
        try {
            if (response != null) {
                response.getClirResponse(serial, REQUEST_NOT_SUPPORTED, new ClirInfo(), false);
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void getColr(int serial) {
        try {
            if (response != null) {
                ColrInfo info = new ColrInfo();
                info.hasErrorDetails = false;
                info.errorDetails = sip();
                response.getColrResponse(serial, REQUEST_NOT_SUPPORTED, info);
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void getImsSubConfig(int serial) {
        try {
            if (response != null) {
                ImsSubConfigInfo info = new ImsSubConfigInfo();
                info.imsStackEnabled = new ArrayList();
                response.getImsSubConfigResponse(serial, REQUEST_NOT_SUPPORTED, info);
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void getRtpErrorStatistics(int serial) {
        try {
            if (response != null) {
                response.getRtpErrorStatisticsResponse(serial, REQUEST_NOT_SUPPORTED, 0);
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void getRtpStatistics(int serial) {
        try {
            if (response != null) {
                response.getRtpStatisticsResponse(serial, REQUEST_NOT_SUPPORTED, 0);
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void hangup(int serial, vendor.qti.hardware.radio.ims.V1_0.HangupRequestInfo info) {
        pair(serial, "hangupResponse");
    }

    public void hold(int serial, int callId) {
        sipCall(serial, "holdResponse");
    }

    public void modifyCallConfirm(int serial, vendor.qti.hardware.radio.ims.V1_0.CallModifyInfo info) {
        pair(serial, "modifyCallConfirmResponse");
    }

    public void modifyCallInitiate(int serial, vendor.qti.hardware.radio.ims.V1_0.CallModifyInfo info) {
        pair(serial, "modifyCallInitiateResponse");
    }

    public void queryCallForwardStatus(int serial,
            vendor.qti.hardware.radio.ims.V1_0.CallForwardInfo info) {
        try {
            if (response != null) {
                response.queryCallForwardStatusResponse(serial, REQUEST_NOT_SUPPORTED,
                        new ArrayList(), sip());
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void queryServiceStatus(int serial) {
        try {
            if (response != null) {
                response.queryServiceStatusResponse(serial, REQUEST_NOT_SUPPORTED, new ArrayList());
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void resume(int serial, int callId) {
        sipCall(serial, "resumeResponse");
    }

    public void sendDtmf(int serial, vendor.qti.hardware.radio.ims.V1_0.DtmfInfo info) {
        pair(serial, "sendDtmfResponse");
    }

    public void sendGeolocationInfo(int serial, double lat, double lon,
            vendor.qti.hardware.radio.ims.V1_0.AddressInfo info) {
        pair(serial, "sendGeolocationInfoResponse");
    }

    public void sendRttMessage(int serial, String message) {
        pair(serial, "sendRttMessageResponse");
    }

    public void setCallForwardStatus(int serial,
            vendor.qti.hardware.radio.ims.V1_0.CallForwardInfo info) {
        try {
            if (response != null) {
                SuppServiceStatus status = supp();
                response.suppServiceStatusResponse(serial, REQUEST_NOT_SUPPORTED, status);
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void setCallWaiting(int serial, int enable, int serviceClass) {
        try {
            if (response != null) {
                response.suppServiceStatusResponse(serial, REQUEST_NOT_SUPPORTED, supp());
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void setClir(int serial, vendor.qti.hardware.radio.ims.V1_0.ClirInfo info) {
        pair(serial, "setClirResponse");
    }

    public void setColr(int serial, vendor.qti.hardware.radio.ims.V1_0.ColrInfo info) {
        pair(serial, "setColrResponse");
    }

    public void setServiceStatus(int serial,
            vendor.qti.hardware.radio.ims.V1_0.ServiceStatusInfo info) {
        pair(serial, "setServiceStatusResponse");
    }

    public void setSuppServiceNotification(int serial, int enable) {
        try {
            if (response != null) {
                response.setSuppServiceNotificationResponse(serial, REQUEST_NOT_SUPPORTED, 0);
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    public void setUiTtyMode(int serial, vendor.qti.hardware.radio.ims.V1_0.TtyInfo info) {
        pair(serial, "setUiTTYModeResponse");
    }

    public void startDtmf(int serial, vendor.qti.hardware.radio.ims.V1_0.DtmfInfo info) {
        pair(serial, "startDtmfResponse");
    }

    public void stopDtmf(int serial) {
        pair(serial, "stopDtmfResponse");
    }

    public void suppServiceStatus(int serial, int operation, int facility,
            vendor.qti.hardware.radio.ims.V1_0.CbNumListInfo info) {
        try {
            if (response != null) {
                response.suppServiceStatusResponse(serial, REQUEST_NOT_SUPPORTED, supp());
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    private void unsupported(int serial) {
        pair(serial, "requestRegistrationChangeResponse");
    }

    private void pair(int serial, String method) {
        try {
            if (response == null) return;
            if ("addParticipantResponse".equals(method)) response.addParticipantResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("answerResponse".equals(method)) response.answerResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("cancelModifyCallResponse".equals(method)) response.cancelModifyCallResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("deflectCallResponse".equals(method)) response.deflectCallResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("dialResponse".equals(method)) response.dialResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("exitEmergencyCallbackModeResponse".equals(method)) response.exitEmergencyCallbackModeResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("explicitCallTransferResponse".equals(method)) response.explicitCallTransferResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("hangupResponse".equals(method)) response.hangupResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("modifyCallConfirmResponse".equals(method)) response.modifyCallConfirmResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("modifyCallInitiateResponse".equals(method)) response.modifyCallInitiateResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("requestRegistrationChangeResponse".equals(method)) response.requestRegistrationChangeResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("sendDtmfResponse".equals(method)) response.sendDtmfResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("sendGeolocationInfoResponse".equals(method)) response.sendGeolocationInfoResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("sendRttMessageResponse".equals(method)) response.sendRttMessageResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("setClirResponse".equals(method)) response.setClirResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("setServiceStatusResponse".equals(method)) response.setServiceStatusResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("startDtmfResponse".equals(method)) response.startDtmfResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("stopDtmfResponse".equals(method)) response.stopDtmfResponse(serial, REQUEST_NOT_SUPPORTED);
            else if ("setUiTTYModeResponse".equals(method)) response.setUiTTYModeResponse(serial, REQUEST_NOT_SUPPORTED);
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    private void sipCall(int serial, String method) {
        try {
            if (response == null) return;
            if ("holdResponse".equals(method)) response.holdResponse(serial, REQUEST_NOT_SUPPORTED, sip());
            else response.resumeResponse(serial, REQUEST_NOT_SUPPORTED, sip());
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    private static SipErrorInfo sip() {
        SipErrorInfo info = new SipErrorInfo();
        info.errorString = "";
        return info;
    }

    private static ConfigInfo emptyConfig() {
        ConfigInfo info = new ConfigInfo();
        info.stringValue = "";
        return info;
    }

    private static SuppServiceStatus supp() {
        SuppServiceStatus status = new SuppServiceStatus();
        status.failureCause = "";
        status.hasErrorDetails = false;
        status.errorDetails = sip();
        status.cbNumListInfo = new ArrayList();
        return status;
    }

    /** IMSA status byte: 0 not registered, 1 registering, 2 registered. */
    private static int hidlState(int qmiStatus) {
        if (qmiStatus == 0) return NOT_REGISTERED;
        if (qmiStatus == 1) return REGISTERING;
        if (qmiStatus == 2) return REGISTERED;
        return INVALID;
    }

    private static int queryImsaStatus() {
        Process process = null;
        try {
            process = new ProcessBuilder("/vendor/bin/ims_reg_query").start();
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line = reader.readLine();
            int code = process.waitFor();
            if (line == null || code != 0) return -1;
            int valid = field(line, "valid=");
            int init = field(line, "init=");
            int msg = field(line, "msg=");
            int status = field(line, "status=");
            if (init != 0 || msg != 0 || valid != 1 || status < 0) return -1;
            return status;
        } catch (Throwable t) {
            t.printStackTrace();
            return -1;
        } finally {
            if (process != null) process.destroy();
        }
    }

    private static int field(String line, String key) {
        int at = line.indexOf(key);
        if (at < 0) return -1;
        int start = at + key.length();
        int end = start;
        if (end < line.length() && line.charAt(end) == '-') end++;
        while (end < line.length() && line.charAt(end) >= '0' && line.charAt(end) <= '9') end++;
        if (end == start || (end == start + 1 && line.charAt(start) == '-')) return -1;
        try {
            return Integer.parseInt(line.substring(start, end));
        } catch (NumberFormatException e) {
            return -1;
        }
    }
}
