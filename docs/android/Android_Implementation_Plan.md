# AIHomeRun Android 实施方案

## 目录
1. [项目概述](#1-项目概述)
2. [技术架构](#2-技术架构)
3. [iOS → Android 技术映射](#3-ios--android-技术映射)
4. [模块详细设计](#4-模块详细设计)
5. [Wear OS 手表端](#5-wear-os-手表端)
6. [开发计划与里程碑](#6-开发计划与里程碑)
7. [文件结构](#7-文件结构)

---

## 1. 项目概述

### 1.1 目标
将 AIHomeRun iOS 应用完整移植到 Android 平台，包括：
- 📱 Android 手机应用（对标 iPhone 端全部功能）
- ⌚ Wear OS 手表应用（对标 Apple Watch 端全部功能）
- 🔗 复用现有后端 API（`https://api.aihomerun.app`）和 Supabase 数据库

### 1.2 核心功能清单

| # | 功能模块 | iOS 实现 | Android 对标 |
|---|---------|---------|-------------|
| 1 | 视频上传 & AI 分析 | PhotosPicker + /analyze API | MediaStore + 同一 API |
| 2 | 骨骼姿态检测 (2D) | Vision VNDetectHumanBodyPoseRequest | ML Kit Pose Detection |
| 3 | 骨骼姿态检测 (3D) | Vision VNHumanBodyPose3DObservation | MediaPipe Pose Landmarker (33 landmarks, world coords) |
| 4 | 视频回放 & 骨骼叠加 | AVPlayer + SkeletonOverlayView | ExoPlayer + Custom Canvas Overlay |
| 5 | 手表 IMU 挥棒检测 | CoreMotion CMBatchedSensorManager | Wear OS SensorManager (加速度+陀螺仪) |
| 6 | 多模态传感器融合 | FusionAnalysisService | 直接移植算法 |
| 7 | 健康数据 | HealthKit | Health Connect API |
| 8 | AI 教练 | Claude API | 同一 API |
| 9 | 场地预订 | MapKit + Google Places | Google Maps + Google Places |
| 10 | 排行榜 | Supabase | 同一 Supabase |
| 11 | 用户/儿童管理 | Supabase Auth + DB | Supabase Android SDK |
| 12 | 会话历史 & 视频回放 | VideoURLStore | Room DB + local file |
| 13 | 对比分析 | ComparisonView | Side-by-side + Ghost overlay |
| 14 | 手表连接 | WatchConnectivity | Wear OS DataClient/MessageClient |

---

## 2. 技术架构

### 2.1 技术栈

```
┌─────────────────────────────────────────┐
│         Android Phone App               │
│  Language: Kotlin                       │
│  UI: Jetpack Compose                    │
│  Architecture: MVVM + Clean Arch        │
│  DI: Hilt                               │
│  Async: Kotlin Coroutines + Flow        │
│  Navigation: Compose Navigation         │
├─────────────────────────────────────────┤
│  Core Libraries:                        │
│  ● ML Kit Pose Detection (2D)           │
│  ● MediaPipe Pose Landmarker (3D)       │
│  ● ExoPlayer (video playback)           │
│  ● CameraX (录制, 未来)                  │
│  ● Google Maps SDK + Places SDK         │
│  ● Supabase Kotlin SDK                  │
│  ● Google Sign-In (Credential Manager)  │
│  ● Health Connect API                   │
│  ● Retrofit + OkHttp (网络)              │
│  ● Room (本地缓存)                       │
│  ● Coil (图片加载)                       │
│  ● Accompanist (权限/系统UI)             │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│         Wear OS Watch App               │
│  Language: Kotlin                       │
│  UI: Compose for Wear OS                │
│  Sensors: SensorManager                 │
│  Sync: Wear OS DataLayer API            │
│  Health: Health Services API            │
│  Workout: ExerciseClient                │
└─────────────────────────────────────────┘
```

### 2.2 整体架构图

```
┌──────────┐      DataLayer API      ┌──────────┐
│ Wear OS  │◄──────────────────────►│ Android  │
│  Watch   │  MessageClient          │  Phone   │
│          │  DataClient             │          │
│ Sensors: │  ChannelClient          │ ML Kit   │
│ Accel    │                         │ MediaPipe│
│ Gyro     │                         │ ExoPlayer│
│ HR       │                         │ Maps     │
└──────────┘                         └────┬─────┘
                                          │ HTTPS
                                     ┌────▼─────┐
                                     │ Backend  │
                                     │ /analyze │
                                     │ Supabase │
                                     │ Claude   │
                                     │ Places   │
                                     └──────────┘
```

---

## 3. iOS → Android 技术映射

### 3.1 框架对照表

| iOS 框架 | Android 替代 | 说明 |
|---------|-------------|------|
| SwiftUI | Jetpack Compose | 声明式 UI |
| Combine | Kotlin Flow | 响应式数据流 |
| @StateObject/@ObservedObject | ViewModel + StateFlow | 状态管理 |
| Vision (2D Pose) | ML Kit Pose Detection | 33 landmarks vs 19 |
| Vision (3D Pose, iOS 17) | MediaPipe Pose Landmarker | 世界坐标系 |
| AVFoundation / AVPlayer | ExoPlayer / Media3 | 视频播放 |
| CoreMotion | Android SensorManager | IMU 传感器 |
| CMBatchedSensorManager | SensorManager SENSOR_DELAY_FASTEST | 高频采集 (~200Hz) |
| HealthKit | Health Connect API | 健康数据 |
| WatchConnectivity | Wear OS DataLayer API | 手表通信 |
| MapKit | Google Maps SDK | 地图 |
| CoreLocation | FusedLocationProvider | 定位 |
| SceneKit (3D) | Sceneform / Filament | 3D 渲染 |
| KeychainService | EncryptedSharedPreferences | 安全存储 |
| UserDefaults | DataStore / SharedPreferences | 轻量存储 |
| FileManager | Context.filesDir / Room | 文件/数据库 |
| CryptoKit SHA256 | java.security.MessageDigest | 哈希 |
| PhotosPicker | Intent(ACTION_PICK) / MediaStore | 媒体选择 |
| URLSession | Retrofit + OkHttp | 网络请求 |

### 3.2 关键差异与注意事项

#### 姿态检测 (Pose Detection)
- **iOS Vision**: 19 landmarks（nose, eyes, ears, neck, shoulders, elbows, wrists, root, hips, knees, ankles）
- **Android ML Kit**: 33 landmarks（增加了 mouth, pinky, index, thumb, heel, foot index）
- **映射方案**: 创建 JointMapping 适配层，将 ML Kit 33 点映射到 iOS 19 点 + 利用额外点增强分析

```kotlin
enum class JointName {
    NOSE, LEFT_EYE, RIGHT_EYE, LEFT_EAR, RIGHT_EAR,
    LEFT_SHOULDER, RIGHT_SHOULDER, LEFT_ELBOW, RIGHT_ELBOW,
    LEFT_WRIST, RIGHT_WRIST, LEFT_HIP, RIGHT_HIP,
    LEFT_KNEE, RIGHT_KNEE, LEFT_ANKLE, RIGHT_ANKLE,
    // Android 额外点 (可增强分析精度)
    LEFT_PINKY, RIGHT_PINKY, LEFT_INDEX, RIGHT_INDEX,
    LEFT_THUMB, RIGHT_THUMB, LEFT_HEEL, RIGHT_HEEL,
    LEFT_FOOT_INDEX, RIGHT_FOOT_INDEX
}
```

#### 传感器频率
- **Apple Watch Series 8+**: 800Hz 加速度, 200Hz 陀螺仪 (CMBatchedSensorManager)
- **Wear OS**: 通常 ~100-200Hz (SENSOR_DELAY_FASTEST)，具体取决于硬件
- **适配方案**: SwingDetector 的阈值和窗口大小需根据实际采样率动态调整

#### 视频处理
- **iOS**: AVAssetReader 逐帧提取 → Vision 分析
- **Android**: MediaMetadataRetriever 或 MediaCodec 逐帧提取 → ML Kit 分析
- 注意: MediaMetadataRetriever.getFrameAtTime() 对高帧率视频较慢，建议用 MediaCodec 解码

---

## 4. 模块详细设计

### 4.1 认证模块 (Auth)

```kotlin
// AuthViewModel.kt
class AuthViewModel @Inject constructor(
    private val supabaseClient: SupabaseClient,
    private val credentialManager: CredentialManager
) : ViewModel() {

    val authState: StateFlow<AuthState>

    // 邮箱登录
    suspend fun signInWithEmail(email: String, password: String)

    // Google 登录 (Credential Manager API)
    suspend fun signInWithGoogle(context: Context)

    // 注册
    suspend fun signUp(email: String, password: String)

    // 密码重置
    suspend fun resetPassword(email: String)

    // 登出
    suspend fun signOut()

    // 删除账户
    suspend fun deleteAccount()
}
```

**依赖:**
- `io.github.jan-tennert.supabase:gotrue-kt` (Supabase Auth)
- `androidx.credentials:credentials` (Google Sign-In)

### 4.2 视频分析模块 (Analysis)

```kotlin
// AnalysisRepository.kt
class AnalysisRepository @Inject constructor(
    private val apiService: AIHomeRunApi,
    private val analysisCache: AnalysisResultCache
) {
    suspend fun analyzeVideo(
        videoUri: Uri,
        actionType: String, // "swing" | "pitch"
        age: Int,
        token: String,
        onProgress: (Float) -> Unit
    ): Result<AnalysisResult>
}

// AIHomeRunApi.kt (Retrofit)
interface AIHomeRunApi {
    @Multipart
    @POST("analyze")
    suspend fun analyzeVideo(
        @Part file: MultipartBody.Part,
        @Part("action_type") actionType: RequestBody,
        @Part("age") age: RequestBody,
        @Header("Authorization") token: String
    ): Response<AnalysisResult>
}
```

### 4.3 姿态检测模块 (Pose Detection)

```kotlin
// PoseDetectionService.kt
class PoseDetectionService @Inject constructor(
    private val context: Context
) {
    private val poseDetector = PoseDetection.getClient(
        AccuratePoseDetectorOptions.Builder()
            .setDetectorMode(AccuratePoseDetectorOptions.SINGLE_IMAGE_MODE)
            .build()
    )

    /**
     * 从视频提取每帧姿态 (≤30fps)
     */
    suspend fun analyzeVideo(videoUri: Uri): VideoPoseData {
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(context, videoUri)
        val duration = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_DURATION
        )?.toLong() ?: 0

        val frameInterval = 1_000_000L / 30 // 30fps → microseconds
        val frames = mutableListOf<FramePose>()

        var time = 0L
        while (time < duration * 1000) {
            val bitmap = retriever.getFrameAtTime(time, OPTION_CLOSEST)
            bitmap?.let {
                val inputImage = InputImage.fromBitmap(it, 0)
                val pose = poseDetector.process(inputImage).await()
                frames.add(mapPoseToFrame(pose, time))
            }
            time += frameInterval
        }

        return VideoPoseData(frames = frames, frameRate = 30.0)
    }

    private fun mapPoseToFrame(pose: Pose, timestamp: Long): FramePose {
        val joints = JointName.entries.mapNotNull { jointName ->
            val landmarkType = jointName.toMLKitLandmark() ?: return@mapNotNull null
            val landmark = pose.getPoseLandmark(landmarkType) ?: return@mapNotNull null
            PoseJoint(
                name = jointName,
                x = landmark.position.x / imageWidth, // normalized
                y = landmark.position.y / imageHeight,
                confidence = landmark.inFrameLikelihood
            )
        }
        return FramePose(timestamp = timestamp, joints = joints)
    }
}

// Pose3DDetectionService.kt (MediaPipe)
class Pose3DDetectionService @Inject constructor(
    private val context: Context
) {
    private val poseLandmarker = PoseLandmarker.createFromOptions(
        context,
        PoseLandmarkerOptions.builder()
            .setBaseOptions(BaseOptions.builder()
                .setModelAssetPath("pose_landmarker_heavy.task")
                .setDelegate(Delegate.GPU)
                .build())
            .setRunningMode(RunningMode.VIDEO)
            .setNumPoses(1)
            .setOutputSegmentationMasks(false)
            .build()
    )

    /**
     * 从视频提取 3D 世界坐标姿态
     */
    suspend fun analyzeVideo3D(videoUri: Uri): VideoPose3DData {
        // MediaPipe returns world landmarks in meters (root-relative)
        // Similar to iOS VNHumanBodyPose3DObservation
    }
}
```

### 4.4 视频回放 & 骨骼叠加

```kotlin
// VideoReplayScreen.kt (Compose)
@Composable
fun VideoReplayScreen(
    videoUri: Uri,
    poseData: VideoPoseData?,
    modifier: Modifier = Modifier
) {
    val exoPlayer = remember {
        ExoPlayer.Builder(context).build().apply {
            setMediaItem(MediaItem.fromUri(videoUri))
            prepare()
        }
    }

    Box(modifier) {
        // ExoPlayer 视频层
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false
                }
            }
        )

        // 骨骼叠加层 (Canvas)
        poseData?.let { data ->
            SkeletonOverlay(
                poseData = data,
                currentTimeMs = exoPlayer.currentPosition,
                modifier = Modifier.matchParentSize()
            )
        }

        // 控制层 (播放/暂停/进度条/速度)
        VideoControls(
            player = exoPlayer,
            modifier = Modifier.matchParentSize()
        )
    }
}

// SkeletonOverlay.kt
@Composable
fun SkeletonOverlay(
    poseData: VideoPoseData,
    currentTimeMs: Long,
    modifier: Modifier
) {
    Canvas(modifier = modifier) {
        val frame = poseData.frameAt(currentTimeMs) ?: return@Canvas

        // 绘制骨骼连线
        SkeletonConnection.all.forEach { conn ->
            val from = frame.joint(conn.from) ?: return@forEach
            val to = frame.joint(conn.to) ?: return@forEach
            drawLine(
                color = conn.color,
                start = Offset(from.x * size.width, from.y * size.height),
                end = Offset(to.x * size.width, to.y * size.height),
                strokeWidth = 3.dp.toPx(),
                cap = StrokeCap.Round
            )
        }

        // 绘制关节点
        frame.joints.forEach { joint ->
            drawCircle(
                color = Color.White,
                radius = 4.dp.toPx(),
                center = Offset(joint.x * size.width, joint.y * size.height)
            )
        }
    }
}
```

### 4.5 传感器融合 (Fusion)

```kotlin
// FusionAnalysisService.kt
class FusionAnalysisService @Inject constructor() {

    /**
     * 融合视频姿态 + 手表 IMU 数据
     * 算法直接从 iOS 移植
     */
    fun fuse(
        videoMetrics: VideoMetrics,  // 来自 /analyze API
        watchSession: SwingSession,  // 来自 Wear OS
        playerAge: Int
    ): FusionResult {

        // 1. 校准棒头速度
        val batLeverRatio = getBatLeverRatio(playerAge) // 2.5-3.5x
        val hipShoulderSep = videoMetrics.hipShoulderSeparation ?: 25.0
        val refinement = 0.85 + (hipShoulderSep / 35.0) * 0.30
        val calibratedSpeed = watchSession.avgHandSpeed * batLeverRatio * refinement

        // 2. 计算 Power Index
        val accelScore = normalizeAcceleration(watchSession.peakAccelG, playerAge)
        val hipScore = (hipShoulderSep / 45.0).coerceIn(0.0, 1.0)
        val followScore = if (videoMetrics.followThrough) 1.0 else 0.6
        val rotationScore = normalizeRotation(watchSession.peakRotation, playerAge)

        val powerIndex = (accelScore * 0.35 + hipScore * 0.25 +
                         followScore * 0.15 + rotationScore * 0.25) * 100

        // 3. 融合置信度
        val confidence = when {
            videoMetrics != null && watchSession != null -> 0.95
            videoMetrics != null -> 0.65
            watchSession != null -> 0.70
            else -> 0.0
        }

        return FusionResult(
            calibratedBatSpeedMPH = calibratedSpeed,
            powerIndex = powerIndex,
            timingScore = calculateTiming(watchSession),
            biomechanicalEfficiency = calculateEfficiency(videoMetrics, watchSession),
            fusionConfidence = confidence
        )
    }

    private fun getBatLeverRatio(age: Int): Double = when {
        age <= 8 -> 2.5
        age <= 10 -> 2.7
        age <= 12 -> 2.9
        age <= 14 -> 3.1
        age <= 16 -> 3.3
        else -> 3.5
    }
}
```

### 4.6 本地数据持久化

```kotlin
// Room Database
@Database(
    entities = [
        CachedAnalysis::class,
        CachedPoseData::class,
        VideoMapping::class,
        ChildEntity::class
    ],
    version = 1
)
abstract class AIHomeRunDatabase : RoomDatabase() {
    abstract fun analysisDao(): AnalysisDao
    abstract fun poseDao(): PoseDao
    abstract fun videoDao(): VideoDao
    abstract fun childDao(): ChildDao
}

// 分析结果缓存 (对标 AnalysisResultCache)
@Dao
interface AnalysisDao {
    @Query("SELECT * FROM analyses WHERE content_hash = :hash")
    suspend fun getCached(hash: String): CachedAnalysis?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun cache(analysis: CachedAnalysis)
}

// 视频 URL 映射 (对标 VideoURLStore)
@Dao
interface VideoDao {
    @Query("SELECT local_path FROM video_mappings WHERE video_id = :videoId")
    suspend fun getVideoPath(videoId: String): String?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveMapping(mapping: VideoMapping)
}
```

---

## 5. Wear OS 手表端

### 5.1 架构设计

```
┌─────────────────────────────────────┐
│         Wear OS App                  │
│                                      │
│  ┌──────────┐   ┌────────────────┐  │
│  │ UI Layer │   │ Sensor Layer   │  │
│  │ Compose  │   │ SensorManager  │  │
│  │ for Wear │   │ Accel + Gyro   │  │
│  └────┬─────┘   └──────┬─────────┘  │
│       │                │             │
│  ┌────▼────────────────▼─────────┐  │
│  │     SwingDetector             │  │
│  │ (移植 iOS 算法)                │  │
│  │ - 冲击检测 (>8g / >3g)        │  │
│  │ - 挥棒起点回溯                 │  │
│  │ - 手速计算                     │  │
│  │ - 攻击角估算                   │  │
│  │ - 7 项高级指标                 │  │
│  └────────────┬──────────────────┘  │
│               │                      │
│  ┌────────────▼──────────────────┐  │
│  │   DataLayer API               │  │
│  │   MessageClient (实时)        │  │
│  │   DataClient (会话数据)       │  │
│  └───────────────────────────────┘  │
│                                      │
│  ┌───────────────────────────────┐  │
│  │   Health Services API         │  │
│  │   ExerciseClient (心率/运动)  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 5.2 传感器采集

```kotlin
// MotionService.kt (Wear OS)
class MotionService(private val context: Context) {

    private val sensorManager = context.getSystemService<SensorManager>()!!
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val gyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)

    // 数据缓冲区
    private val accelBuffer = mutableListOf<SensorSample>()
    private val gyroBuffer = mutableListOf<SensorSample>()

    var onBatchReady: ((List<SensorSample>, List<SensorSample>) -> Unit)? = null

    fun startCollection() {
        // SENSOR_DELAY_FASTEST: 通常 100-200Hz (设备依赖)
        sensorManager.registerListener(
            accelListener, accelerometer, SensorManager.SENSOR_DELAY_FASTEST
        )
        sensorManager.registerListener(
            gyroListener, gyroscope, SensorManager.SENSOR_DELAY_FASTEST
        )

        // 每秒回调一次批量数据
        scope.launch {
            while (isActive) {
                delay(1000)
                val accelBatch = synchronized(accelBuffer) {
                    accelBuffer.toList().also { accelBuffer.clear() }
                }
                val gyroBatch = synchronized(gyroBuffer) {
                    gyroBuffer.toList().also { gyroBuffer.clear() }
                }
                onBatchReady?.invoke(accelBatch, gyroBatch)
            }
        }
    }

    private val accelListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            synchronized(accelBuffer) {
                accelBuffer.add(SensorSample(
                    timestamp = event.timestamp, // nanoseconds
                    x = event.values[0].toDouble(),
                    y = event.values[1].toDouble(),
                    z = event.values[2].toDouble()
                ))
            }
        }
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }
}
```

### 5.3 挥棒检测 (SwingDetector)

```kotlin
// SwingDetector.kt (Wear OS) - 移植自 iOS
class SwingDetector(private val playerAge: Int) {

    // 配置参数 (与 iOS 一致)
    companion object {
        const val IMPACT_THRESHOLD_STANDARD = 8.0  // g-force
        const val IMPACT_THRESHOLD_AIR = 3.0
        const val ROTATION_THRESHOLD = 100.0       // degrees/sec
        const val MIN_SWING_DURATION_MS = 100
        const val MAX_SWING_DURATION_MS = 1000
        const val COOLDOWN_MS = 800
        const val LOOKBACK_MS = 500
    }

    var practiceMode: PracticeMode = PracticeMode.STANDARD
    var onSwingDetected: ((SwingEvent) -> Unit)? = null

    private var lastSwingTime = 0L

    fun processBatch(
        accelSamples: List<SensorSample>,
        gyroSamples: List<SensorSample>
    ) {
        val threshold = when (practiceMode) {
            PracticeMode.STANDARD -> IMPACT_THRESHOLD_STANDARD
            PracticeMode.AIR_SWING -> IMPACT_THRESHOLD_AIR
        }

        // 1. 寻找加速度峰值 (冲击点)
        for (sample in accelSamples) {
            val magnitude = sqrt(sample.x.pow(2) + sample.y.pow(2) + sample.z.pow(2)) / 9.81

            if (magnitude > threshold) {
                val now = sample.timestamp / 1_000_000 // ns → ms
                if (now - lastSwingTime < COOLDOWN_MS) continue

                // 2. 回溯寻找挥棒起点
                val swingStart = findSwingStart(gyroSamples, sample.timestamp)
                val duration = (now - (swingStart / 1_000_000))

                if (duration in MIN_SWING_DURATION_MS..MAX_SWING_DURATION_MS) {
                    // 3. 计算指标
                    val handSpeed = calculateHandSpeed(gyroSamples, swingStart, sample.timestamp)
                    val attackAngle = calculateAttackAngle(accelSamples, sample.timestamp)
                    val barrelSpeed = calculateBarrelSpeed(accelSamples, gyroSamples, sample.timestamp)
                    val swingPlane = calculateSwingPlaneAngle(gyroSamples, swingStart, sample.timestamp)
                    val powerTransfer = calculatePowerTransferEfficiency(accelSamples, sample.timestamp)
                    val loadTime = calculateLoadTime(gyroSamples, swingStart)
                    val snapScore = calculateSnapScore(gyroSamples, sample.timestamp)
                    val kineticChain = calculateKineticChainScore(accelSamples, gyroSamples, swingStart, sample.timestamp)
                    val connection = calculateConnectionScore(accelSamples, gyroSamples, swingStart, sample.timestamp)

                    val event = SwingEvent(
                        timestamp = now,
                        handSpeedMPH = handSpeed,
                        peakAccelerationG = magnitude,
                        attackAngleDegrees = attackAngle,
                        swingDurationMS = duration,
                        impactDetected = practiceMode == PracticeMode.STANDARD,
                        barrelSpeedMPH = barrelSpeed,
                        swingPlaneAngle = swingPlane,
                        powerTransferEfficiency = powerTransfer,
                        loadTimeMS = loadTime,
                        snapScore = snapScore,
                        kineticChainScore = kineticChain,
                        connectionScore = connection
                    )

                    lastSwingTime = now
                    onSwingDetected?.invoke(event)
                }
            }
        }
    }

    /**
     * 棒头速度 = max(sqrt(a*r), omega*r)
     * r = 年龄对应球棒长度
     */
    private fun calculateBarrelSpeed(
        accel: List<SensorSample>,
        gyro: List<SensorSample>,
        impactTime: Long
    ): Double {
        val batLength = referenceBatLength(playerAge)
        // ... 移植 iOS calculateBarrelSpeed 算法
        return speed * 2.23694 // m/s → mph
    }

    private fun referenceBatLength(age: Int): Double = when {
        age <= 6 -> 0.635   // 25 inches
        age <= 8 -> 0.686   // 27 inches
        age <= 10 -> 0.737  // 29 inches
        age <= 12 -> 0.787  // 31 inches
        age <= 14 -> 0.826  // 32.5 inches
        else -> 0.851       // 33.5 inches
    }
}
```

### 5.4 手表 ↔ 手机通信

```kotlin
// WearDataService.kt (Wear OS side)
class WearDataService(private val context: Context) {

    private val dataClient = Wearable.getDataClient(context)
    private val messageClient = Wearable.getMessageClient(context)

    /**
     * 发送完整会话数据到手机
     */
    suspend fun sendSession(session: SwingSession) {
        val json = Json.encodeToString(session)
        val request = PutDataMapRequest.create("/session").apply {
            dataMap.putString("session_json", json)
            dataMap.putLong("timestamp", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()

        dataClient.putDataItem(request).await()
    }

    /**
     * 实时发送单次挥棒数据
     */
    suspend fun sendSwingUpdate(swing: SwingEvent) {
        val json = Json.encodeToString(swing)
        val nodes = Wearable.getNodeClient(context).connectedNodes.await()
        nodes.forEach { node ->
            messageClient.sendMessage(
                node.id, "/swing_update", json.toByteArray()
            ).await()
        }
    }
}

// WatchSessionManager.kt (Phone side)
class WatchSessionManager(private val context: Context) : DataClient.OnDataChangedListener {

    private val _sessions = MutableStateFlow<List<SwingSession>>(emptyList())
    val sessions: StateFlow<List<SwingSession>> = _sessions

    private val _latestSwing = MutableSharedFlow<SwingEvent>()
    val latestSwing: SharedFlow<SwingEvent> = _latestSwing

    fun startListening() {
        Wearable.getDataClient(context).addListener(this)

        // 监听实时挥棒消息
        Wearable.getMessageClient(context).addListener { event ->
            when (event.path) {
                "/swing_update" -> {
                    val swing = Json.decodeFromString<SwingEvent>(String(event.data))
                    scope.launch { _latestSwing.emit(swing) }
                }
            }
        }
    }

    override fun onDataChanged(events: DataEventBuffer) {
        events.forEach { event ->
            if (event.type == DataEvent.TYPE_CHANGED &&
                event.dataItem.uri.path == "/session") {
                val data = DataMapItem.fromDataItem(event.dataItem).dataMap
                val json = data.getString("session_json")
                val session = Json.decodeFromString<SwingSession>(json)
                _sessions.value = _sessions.value + session
            }
        }
    }
}
```

### 5.5 健康数据 (Health Connect)

```kotlin
// HealthService.kt (Phone)
class HealthService(private val context: Context) {

    private val healthClient = HealthConnectClient.getOrCreate(context)

    /**
     * 读取最近的训练数据
     */
    suspend fun getRecentWorkouts(): List<ExerciseSessionRecord> {
        val request = ReadRecordsRequest(
            recordType = ExerciseSessionRecord::class,
            timeRangeFilter = TimeRangeFilter.after(
                Instant.now().minus(30, ChronoUnit.DAYS)
            )
        )
        return healthClient.readRecords(request).records
    }

    /**
     * 保存棒球训练 session
     */
    suspend fun saveWorkout(session: SwingSession) {
        val record = ExerciseSessionRecord(
            startTime = session.startTime,
            endTime = session.endTime,
            exerciseType = ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL,
            title = "Baseball Practice - ${session.swings.size} swings"
        )
        healthClient.insertRecords(listOf(record))
    }

    /**
     * 读取心率数据
     */
    suspend fun getHeartRateData(start: Instant, end: Instant): List<HeartRateRecord> {
        val request = ReadRecordsRequest(
            recordType = HeartRateRecord::class,
            timeRangeFilter = TimeRangeFilter.between(start, end)
        )
        return healthClient.readRecords(request).records
    }
}
```

### 5.6 Wear OS UI

```kotlin
// StartScreen.kt (Wear OS Compose)
@Composable
fun StartScreen(
    onStartSession: (PracticeMode) -> Unit
) {
    val scrollState = rememberScalingLazyListState()

    Scaffold(
        timeText = { TimeText() },
        positionIndicator = { PositionIndicator(scrollState) }
    ) {
        ScalingLazyColumn(state = scrollState) {
            item {
                // App Logo
                Image(
                    painter = painterResource(R.drawable.app_logo),
                    modifier = Modifier.size(48.dp)
                )
            }
            item {
                Chip(
                    onClick = { onStartSession(PracticeMode.STANDARD) },
                    label = { Text("Standard Practice") },
                    secondaryLabel = { Text("Ball required") },
                    icon = { Icon(Icons.Default.SportBaseball) }
                )
            }
            item {
                Chip(
                    onClick = { onStartSession(PracticeMode.AIR_SWING) },
                    label = { Text("Air Swing") },
                    secondaryLabel = { Text("No ball needed") },
                    icon = { Icon(Icons.Default.Air) }
                )
            }
        }
    }
}

// LiveSessionScreen.kt
@Composable
fun LiveSessionScreen(
    swingCount: Int,
    lastSpeed: Double?,
    bestSpeed: Double?,
    avgSpeed: Double?,
    heartRate: Int?,
    elapsed: Duration
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        // 环形进度 (心率区间)
        CircularProgressIndicator(
            progress = heartRate?.let { it / 200f } ?: 0f,
            modifier = Modifier.fillMaxSize().padding(4.dp),
            strokeWidth = 6.dp,
            colors = ProgressIndicatorDefaults.colors(
                indicatorColor = heartRateZoneColor(heartRate)
            )
        )

        Column(horizontalAlignment = CenterHorizontally) {
            // 挥棒次数 (大字)
            Text(
                text = "$swingCount",
                style = MaterialTheme.typography.display1,
                color = MaterialTheme.colors.primary
            )
            Text("swings", style = MaterialTheme.typography.caption1)

            Spacer(Modifier.height(8.dp))

            // 最后一击速度
            lastSpeed?.let {
                Text(
                    text = "${it.roundToInt()} MPH",
                    style = MaterialTheme.typography.title2,
                    color = Color.White
                )
            }

            // 心率
            heartRate?.let {
                Row(verticalAlignment = CenterVertically) {
                    Icon(
                        Icons.Default.Favorite,
                        tint = Color.Red,
                        modifier = Modifier.size(12.dp)
                    )
                    Text(" $it BPM", style = MaterialTheme.typography.caption2)
                }
            }
        }
    }
}
```

---

## 6. 开发计划与里程碑

### Phase 1: 核心框架 (2-3 周)
- [ ] 项目初始化 (Kotlin, Compose, Hilt, Room)
- [ ] Supabase Auth 集成 (邮箱 + Google 登录)
- [ ] 用户/儿童 Profile 管理
- [ ] 基础导航结构 (5 个 Tab)
- [ ] 主题系统 (深色/浅色模式)

### Phase 2: 视频分析核心 (3-4 周)
- [ ] 视频选择 & 上传
- [ ] /analyze API 集成 (multipart upload + progress)
- [ ] 分析结果展示 (评分、指标、反馈)
- [ ] ML Kit 2D 姿态检测
- [ ] ExoPlayer 视频回放 + 骨骼叠加
- [ ] 分析结果缓存 (Room)
- [ ] 动作检测 & 视频裁剪

### Phase 3: 高级分析功能 (2-3 周)
- [ ] MediaPipe 3D 姿态 + 3D 渲染
- [ ] 对比分析 (并排 + 幽灵叠加)
- [ ] 历史记录 & 视频回放
- [ ] 进度统计图表
- [ ] PDF 报告导出

### Phase 4: Wear OS 手表 (3-4 周)
- [ ] Wear OS 应用基础框架
- [ ] 传感器采集 (加速度+陀螺仪)
- [ ] SwingDetector 移植 (7 项高级指标)
- [ ] 实时 UI (挥棒计数/速度/心率)
- [ ] DataLayer API 手表↔手机通信
- [ ] Health Services API 心率监测
- [ ] 会话完成 & 数据同步

### Phase 5: 传感器融合 & 专业功能 (2-3 周)
- [ ] FusionAnalysisService 移植
- [ ] WatchMetricsCard / SwingDetailCard / HeatMapView / SessionSummaryCard
- [ ] Health Connect 集成
- [ ] AI Coach (Claude API)
- [ ] 场地预订 (Google Maps + Places)

### Phase 6: 打磨 & 发布 (2 周)
- [ ] UI 细节优化 & 动画
- [ ] 性能优化 (内存/电池)
- [ ] 多设备适配测试
- [ ] Google Play 发布准备
- [ ] Beta 测试

**总估计时间: 14-19 周 (约 3.5-5 个月)**

---

## 7. 文件结构

```
android/
├── app/                              # Phone App
│   ├── src/main/
│   │   ├── java/com/aihomerun/app/
│   │   │   ├── di/                   # Hilt 依赖注入
│   │   │   │   ├── AppModule.kt
│   │   │   │   ├── NetworkModule.kt
│   │   │   │   └── DatabaseModule.kt
│   │   │   │
│   │   │   ├── data/                 # 数据层
│   │   │   │   ├── local/
│   │   │   │   │   ├── AIHomeRunDatabase.kt
│   │   │   │   │   ├── AnalysisDao.kt
│   │   │   │   │   ├── PoseDao.kt
│   │   │   │   │   └── VideoDao.kt
│   │   │   │   ├── remote/
│   │   │   │   │   ├── AIHomeRunApi.kt        # Retrofit
│   │   │   │   │   └── SupabaseClient.kt
│   │   │   │   └── repository/
│   │   │   │       ├── AnalysisRepository.kt
│   │   │   │       ├── AuthRepository.kt
│   │   │   │       ├── ProfileRepository.kt
│   │   │   │       └── SessionRepository.kt
│   │   │   │
│   │   │   ├── domain/               # 领域层
│   │   │   │   ├── model/
│   │   │   │   │   ├── AnalysisResult.kt
│   │   │   │   │   ├── PoseData.kt
│   │   │   │   │   ├── Pose3DData.kt
│   │   │   │   │   ├── SwingSession.kt
│   │   │   │   │   ├── FusionModels.kt
│   │   │   │   │   ├── ProfileModels.kt
│   │   │   │   │   ├── FieldModels.kt
│   │   │   │   │   └── ComparisonModels.kt
│   │   │   │   └── service/
│   │   │   │       ├── PoseDetectionService.kt
│   │   │   │       ├── Pose3DDetectionService.kt
│   │   │   │       ├── ActionDetectionService.kt
│   │   │   │       ├── FusionAnalysisService.kt
│   │   │   │       ├── HealthService.kt
│   │   │   │       ├── WatchSessionManager.kt
│   │   │   │       └── ClaudeApiService.kt
│   │   │   │
│   │   │   ├── ui/                   # 展示层
│   │   │   │   ├── theme/
│   │   │   │   │   ├── Theme.kt
│   │   │   │   │   ├── Color.kt
│   │   │   │   │   └── Type.kt
│   │   │   │   ├── navigation/
│   │   │   │   │   └── AppNavigation.kt
│   │   │   │   ├── components/       # 通用组件
│   │   │   │   │   ├── ScoreRing.kt
│   │   │   │   │   ├── GradeHero.kt
│   │   │   │   │   ├── HrCard.kt
│   │   │   │   │   └── BaseballBanners.kt
│   │   │   │   │
│   │   │   │   ├── auth/
│   │   │   │   │   ├── AuthScreen.kt
│   │   │   │   │   └── AuthViewModel.kt
│   │   │   │   ├── upload/
│   │   │   │   │   ├── UploadScreen.kt
│   │   │   │   │   ├── LoadingScreen.kt
│   │   │   │   │   ├── TrimPreview.kt
│   │   │   │   │   └── UploadViewModel.kt
│   │   │   │   ├── result/
│   │   │   │   │   ├── ResultScreen.kt
│   │   │   │   │   ├── VideoReplay.kt
│   │   │   │   │   ├── SkeletonOverlay.kt
│   │   │   │   │   ├── ProMetricsCard.kt
│   │   │   │   │   ├── WatchMetricsCard.kt
│   │   │   │   │   ├── SwingDetailCard.kt
│   │   │   │   │   ├── HeatMapView.kt
│   │   │   │   │   ├── SessionSummaryCard.kt
│   │   │   │   │   ├── RadarChart.kt
│   │   │   │   │   ├── SpeedDistributionChart.kt
│   │   │   │   │   └── GrowthChart.kt
│   │   │   │   ├── comparison/
│   │   │   │   │   ├── ComparisonScreen.kt
│   │   │   │   │   ├── SideBySideView.kt
│   │   │   │   │   ├── GhostOverlay.kt
│   │   │   │   │   └── ComparisonViewModel.kt
│   │   │   │   ├── profile/
│   │   │   │   │   ├── ProfileScreen.kt
│   │   │   │   │   ├── ChildEditor.kt
│   │   │   │   │   └── ProfileViewModel.kt
│   │   │   │   ├── training/
│   │   │   │   │   └── TrainingScreen.kt
│   │   │   │   ├── rankings/
│   │   │   │   │   └── RankingsScreen.kt
│   │   │   │   ├── aicoach/
│   │   │   │   │   ├── AICoachScreen.kt
│   │   │   │   │   └── PitchCountCard.kt
│   │   │   │   ├── field/
│   │   │   │   │   ├── FieldBookingScreen.kt
│   │   │   │   │   ├── FieldMap.kt
│   │   │   │   │   ├── FieldCard.kt
│   │   │   │   │   └── FieldDetailSheet.kt
│   │   │   │   ├── stats/
│   │   │   │   │   ├── SessionHistoryScreen.kt
│   │   │   │   │   └── ProgressStats.kt
│   │   │   │   └── skeleton3d/
│   │   │   │       └── Skeleton3DView.kt
│   │   │   │
│   │   │   └── AIHomeRunApp.kt       # Application class
│   │   │
│   │   ├── res/
│   │   │   ├── values/
│   │   │   │   ├── colors.xml
│   │   │   │   ├── strings.xml
│   │   │   │   └── themes.xml
│   │   │   └── raw/
│   │   │       └── coach_reference.json
│   │   │
│   │   └── AndroidManifest.xml
│   │
│   └── build.gradle.kts
│
├── wear/                             # Wear OS Watch App
│   ├── src/main/
│   │   ├── java/com/aihomerun/wear/
│   │   │   ├── di/
│   │   │   │   └── WearModule.kt
│   │   │   ├── sensor/
│   │   │   │   ├── MotionService.kt
│   │   │   │   └── SwingDetector.kt
│   │   │   ├── health/
│   │   │   │   └── WorkoutService.kt
│   │   │   ├── sync/
│   │   │   │   └── WearDataService.kt
│   │   │   ├── ui/
│   │   │   │   ├── StartScreen.kt
│   │   │   │   ├── LiveSessionScreen.kt
│   │   │   │   ├── SessionCompleteScreen.kt
│   │   │   │   └── WearTheme.kt
│   │   │   ├── viewmodel/
│   │   │   │   └── SessionViewModel.kt
│   │   │   └── WearApp.kt
│   │   │
│   │   └── AndroidManifest.xml
│   │
│   └── build.gradle.kts
│
├── shared/                           # 共享模块
│   ├── src/main/java/com/aihomerun/shared/
│   │   ├── SwingSession.kt           # 数据模型
│   │   ├── SwingEvent.kt
│   │   └── Constants.kt
│   └── build.gradle.kts
│
├── build.gradle.kts                  # Root
├── settings.gradle.kts
└── gradle.properties
```

---

## 附录: build.gradle.kts 核心依赖

```kotlin
// app/build.gradle.kts
dependencies {
    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.navigation:navigation-compose:2.7.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.4")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.51.1")
    kapt("com.google.dagger:hilt-compiler:2.51.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // ML Kit Pose Detection
    implementation("com.google.mlkit:pose-detection-accurate:18.0.0-beta5")

    // MediaPipe (3D Pose)
    implementation("com.google.mediapipe:tasks-vision:0.10.14")

    // ExoPlayer / Media3
    implementation("androidx.media3:media3-exoplayer:1.3.1")
    implementation("androidx.media3:media3-ui:1.3.1")

    // Supabase
    implementation(platform("io.github.jan-tennert.supabase:bom:2.6.1"))
    implementation("io.github.jan-tennert.supabase:gotrue-kt")
    implementation("io.github.jan-tennert.supabase:postgrest-kt")
    implementation("io.ktor:ktor-client-android:2.3.12")

    // Google Sign-In
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")

    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-kotlinx-serialization:2.11.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")

    // Google Maps
    implementation("com.google.maps.android:maps-compose:6.1.0")
    implementation("com.google.android.libraries.places:places:3.5.0")

    // Health Connect
    implementation("androidx.health.connect:connect-client:1.1.0-alpha07")

    // Wear OS communication (Phone side)
    implementation("com.google.android.gms:play-services-wearable:18.2.0")

    // Charts
    implementation("com.patrykandpatrick.vico:compose-m3:2.0.0-alpha.21")

    // Image loading
    implementation("io.coil-kt:coil-compose:2.7.0")

    // Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")
}

// wear/build.gradle.kts
dependencies {
    implementation("androidx.wear.compose:compose-material:1.3.1")
    implementation("androidx.wear.compose:compose-foundation:1.3.1")
    implementation("androidx.wear.compose:compose-navigation:1.3.1")
    implementation("com.google.android.gms:play-services-wearable:18.2.0")
    implementation("androidx.health:health-services-client:1.1.0-alpha03")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")
}
```
