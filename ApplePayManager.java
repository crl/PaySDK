package com.lingyu.charge.platform;

import static org.apache.commons.lang3.StringUtils.isEmpty;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Date;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.lingyu.charge.ChargeServerContext;
import com.lingyu.charge.GameClientManager;
import com.lingyu.common.constant.AppleErrorCode;
import com.lingyu.common.constant.PlatformConstant;
import com.lingyu.common.db.GameRepository;
import com.lingyu.common.entity.ExchangePoint;
import com.lingyu.common.network.GameClient;
import com.lingyu.msg.http.DeliverGoodsApple_C2S_Msg;
import com.lingyu.msg.http.DeliverGoodsApple_S2C_Msg;

import io.netty.handler.codec.http.FullHttpResponse;

@Service
public class ApplePayManager {
	private static final Logger logger = LogManager.getLogger(ApplePayManager.class);
	private boolean isLocalTest = false;

	@Autowired
	private GameClientManager gameClientManager;
	private GameRepository repository = ChargeServerContext.getGameRepository();

	// http://127.0.0.1:9001/charge/apple/pay.aspx?userInfo=2_xxxx_xxxx_local&productID=1102562958&orderID=241F2CA66817C3AF340B1DF392853FC6&&appID=com.lingyu8.themonkey.648hunyu&&receipt=gsgssds

	public void deliverGoods(Map<String, List<String>> store, FullHttpResponse resp) {

		String userInfo = store.get("userInfo").get(0);
		String[] infos = userInfo.split("_");
		String goodsId = store.get("productID").get(0);
		String sid = infos[0];
		String userId = infos[1];
		String sdkUserId = infos[2];
		String platform = infos[3];
		String orderID = store.get("orderID").get(0);
		String appID = store.get("appID").get(0);
		String receipt = decode(store.get("receipt").get(0));
//		 String receipt =
//		"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";

		logger.info("appID={}", appID);
		logger.info("receipt={}", receipt);
		logger.info("sdkUserId={}", sdkUserId);

		if (isEmpty(goodsId) || isEmpty(sid) || isEmpty(receipt)) {
			if (isEmpty(receipt)) {
				logger.error("param is null~goodsId:{} sid={} ticket={}", goodsId, sid);
			} else {
				logger.error("param is null~goodsId:{} sid={} ticket={} receipt={}", goodsId, sid, receipt.length());
			}
			writeMsg(AppleErrorCode.PARAM, resp);
			return;
		}
		boolean isInSandBox = true;
		String result = "";
		String iapCheckResult = iapCheck(receipt, false);

		String orderId = null;

		try {

			JSONObject jsonObject = JSON.parseObject(iapCheckResult);
			int status = Integer.parseInt(jsonObject.getString("status"));
			if (status != 0) {
				logger.error("param is null~goodsId:{} sid={} ticket={},iapCheckResult={}", goodsId, sid, iapCheckResult, receipt.length());
				iapCheckResult = iapCheck(receipt, true);
				jsonObject = JSON.parseObject(iapCheckResult);
				status = Integer.parseInt(jsonObject.getString("status"));
				// 正式地址验证,验证不过时在沙盒下再次验证
				if (status != 0) {
					logger.error("param is null~goodsId:{} sid={} ticket={},iapCheckResult={}", goodsId, sid, iapCheckResult, receipt.length());
					writeMsg(AppleErrorCode.PARAM, resp);
					return;
				} else {
					isInSandBox = true;
				}
			}
			JSONObject receiptJson = jsonObject.getJSONObject("receipt");
			JSONArray jsonArray = receiptJson.getJSONArray("in_app");
			String productId = jsonArray.getJSONObject(0).get("product_id").toString();
			if (!productId.equals(appID)) {
				logger.error("param is null~goodsId:{} sid={} ticket={},iapCheckResult={} productId={} purchaseDateMs={}", goodsId, sid, iapCheckResult,
						receipt.length(), productId, orderId);
				writeMsg(AppleErrorCode.SIGN, resp);
				return;
			}

			// 判断订单是否重复
			boolean orderExists = repository.isOrderIdExists(orderID);
			if (orderExists) {
				resp.content().writeBytes(JSON.toJSONString(AppleErrorCode.REPEAT).getBytes());
				return;
			}
			if (isInSandBox && isLocalTest) {
				sdkUserId = "004";
				userId = "004";
				platform = "local";
			}
			int time = (int) (new Date().getTime() / 1000);
			int areaId = Integer.parseInt(sid);
			// GameClient gameClient = gameClientManager.getGameClient(platform,
			// areaId);
			// test
			GameClient gameClient = gameClientManager.getGameClient(platform, areaId);
			DeliverGoodsApple_S2C_Msg msg = gameClient
					.deliverGoods(new DeliverGoodsApple_C2S_Msg(platform, areaId, userId, time, orderID, goodsId, sdkUserId, appID));

			ExchangePoint exchange = msg.getExchange();
			try {
				repository.createExchange(exchange);
			} catch (Exception e) {
				logger.error("e.getMessage()={}", e.getMessage());
			}
			result = convertParam(1, exchange.getGamePoint() + "元宝");
			resp.content().writeBytes(result.getBytes());
		} catch (Exception e) {
			logger.error("", e);
			logger.error("receipt check~={}", iapCheckResult);
			writeMsg(AppleErrorCode.ServerBusy, resp);
		}
	}

	/**
	 * IAP沙盒验证
	 * 
	 * @param receipt
	 * @return
	 */
	private String iapCheck(String receipt, boolean isSandBox) {
		String url = "https://buy.itunes.apple.com/verifyReceipt";
		if (isSandBox) {
			url = "https://sandbox.itunes.apple.com/verifyReceipt";
		}
		String result = "";// 返回的结果
		if (receipt != null) {
			try {
				URL dataUrl = new URL(url);
				HttpURLConnection con = (HttpURLConnection) dataUrl.openConnection();
				con.setRequestMethod("POST");
				con.setRequestProperty("content-type", "application/json");
				con.setRequestProperty("Proxy-Connection", "Keep-Alive");
				con.setDoOutput(true);
				con.setDoInput(true);
				OutputStreamWriter out = new OutputStreamWriter(con.getOutputStream());
				String jsonValue = "{\"receipt-data\":\"" + receipt + "\"}";
				out.write(jsonValue);
				out.flush();
				out.close();
				InputStream is = con.getInputStream();
				BufferedReader reader = new BufferedReader(new InputStreamReader(is));
				String line = null;
				while ((line = reader.readLine()) != null) {
					result += line + "\r\n";
				}
			} catch (Exception e) {
				logger.error("e.getMessage()={}", e.getMessage());
				// LOG.error(e.getMessage());
			}
		}
		return result;
	}

	/**
	 * 输出消息
	 * 
	 * @param i
	 * @param s
	 * @return
	 */
	private static String convertParam(int i, String s) {
		JSONObject jsonObject = new JSONObject();
		jsonObject.put("code", Integer.valueOf(i));
		jsonObject.put("data", s);
		return jsonObject.toJSONString();
	}

	public static void main(String[] args) {
		System.out.println(convertParam(1, "asdfasdf"));
		System.out.println(JSON.toJSONString(convertParam(1, "asdfasdf")));
	}

	/** 返回客户端 */
	private void writeMsg(AppleErrorCode errorCode, FullHttpResponse resp) {
		String jsonStr = JSON.toJSONString(errorCode);
		try {
			resp.content().writeBytes(jsonStr.getBytes("UTF-8"));
		} catch (Exception e) {
			logger.error("获取{}的UTF-8字节流出错，返回默认编码字节流", jsonStr);
			resp.content().writeBytes(jsonStr.getBytes());
		}
	}

	public String decode(String str) {
		String secureStr = str.replace("-", "+").replace("_", "/");
		switch (secureStr.length() % 4) {
		case 2: {
			secureStr += "==";
			break;
		}
		case 3: {
			secureStr += "=";
			break;
		}
		}
		return secureStr;
	}
}
