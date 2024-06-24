use anyhow::Result;
use flowy_sidecar::process::SidecarCommand;
use serde_json::json;
use std::sync::Once;
use tracing::info;
use tracing_subscriber::fmt::Subscriber;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

#[tokio::test]
async fn load_chat_model_test() {
  if let Ok(config) = LocalAIConfiguration::new() {
    let (mut rx, mut child) = SidecarCommand::new_sidecar(&config.chat_bin_path)
      .unwrap()
      .spawn()
      .unwrap();

    tokio::spawn(async move {
      while let Some(event) = rx.recv().await {
        info!("event: {:?}", event);
      }
    });

    let json = json!({
        "plugin_id": "example_plugin_id",
        "method": "initialize",
        "params": {
            "absolute_chat_model_path":config.chat_model_absolute_path(),
        }
    });
    child.write_json(json).unwrap();
    tokio::time::sleep(tokio::time::Duration::from_secs(15)).await;

    // let chat_id = uuid::Uuid::new_v4().to_string();
    // let json =
    //   json!({"chat_id": chat_id, "method": "answer", "params": {"content": "hello world"}});
    // child.write_json(json).unwrap();
    //
    // tokio::time::sleep(tokio::time::Duration::from_secs(15)).await;
    // child.kill().unwrap();
  }
}

pub struct LocalAIConfiguration {
  root: String,
  chat_bin_path: String,
  chat_model_name: String,
}

impl LocalAIConfiguration {
  pub fn new() -> Result<Self> {
    dotenv::dotenv().ok();
    setup_log();

    // load from .env
    let root = dotenv::var("LOCAL_AI_ROOT_PATH")?;
    let chat_bin_path = dotenv::var("CHAT_BIN_PATH")?;
    let chat_model = dotenv::var("LOCAL_AI_CHAT_MODEL_NAME")?;

    Ok(Self {
      root,
      chat_bin_path,
      chat_model_name: chat_model,
    })
  }

  pub fn chat_model_absolute_path(&self) -> String {
    format!("{}/{}", self.root, self.chat_model_name)
  }
}

pub fn setup_log() {
  static START: Once = Once::new();
  START.call_once(|| {
    let level = "trace";
    let mut filters = vec![];
    filters.push(format!("flowy_sidecar={}", level));
    std::env::set_var("RUST_LOG", filters.join(","));

    let subscriber = Subscriber::builder()
      .with_env_filter(EnvFilter::from_default_env())
      .with_ansi(true)
      .finish();
    subscriber.try_init().unwrap();
  });
}
