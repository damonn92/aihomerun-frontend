# Patent Claims

## Title
Multi-Modal Sensor Fusion System for Baseball Swing Analysis Using Wearable IMU and Video Pose Estimation

---

## Independent Claims

### Claim 1: Multi-Modal Sensor Fusion Method for Athletic Motion Analysis

A computer-implemented method for analyzing baseball swing mechanics, comprising:

(a) receiving, from a wrist-worn wearable device comprising inertial measurement unit (IMU) sensors, a data stream comprising tri-axial accelerometer measurements at a sample rate of at least 100 Hz and tri-axial gyroscope measurements, said data stream associated with one or more baseball swing events;

(b) receiving, from a video recording device, a plurality of video frames depicting a baseball swing performed by the same player;

(c) extracting, from the video frames using a body pose estimation model, a set of body joint positions for each of a plurality of frames, said joint positions comprising at least shoulder, elbow, wrist, hip, knee, and ankle positions;

(d) temporally aligning the IMU data stream with the video frames by identifying corresponding swing initiation and completion events in both data modalities;

(e) computing a calibrated bat speed by:
   (i) determining a raw wrist velocity from the IMU accelerometer data,
   (ii) measuring a limb segment proportion from the video-derived joint positions, specifically the ratio of shoulder-to-wrist distance to overall body height,
   (iii) applying an age-appropriate lever-arm correction factor to convert wrist velocity to estimated bat head velocity, and
   (iv) refining the estimate using a body mechanics efficiency factor derived from video-measured hip-shoulder separation angle;

(f) computing a biomechanical efficiency metric by combining:
   (i) a video-derived body mechanics score comprising balance stability, joint angle conformity to ideal ranges, and hip-shoulder separation quality, with
   (ii) an IMU-derived rotational efficiency score comprising the ratio of peak angular velocity to peak linear acceleration, weighted and combined to produce a single efficiency value;

(g) outputting the calibrated bat speed, biomechanical efficiency metric, and associated confidence score to a user interface.

### Claim 2: Real-Time Swing Detection with Impact Classification

A method for detecting and classifying baseball swing events using a wrist-worn wearable device, comprising:

(a) continuously monitoring tri-axial accelerometer and gyroscope signals from a wrist-worn inertial measurement unit;

(b) detecting swing initiation when angular velocity magnitude exceeds a first threshold, transitioning from an idle state to a loading state;

(c) confirming swing execution when an acceleration pattern matching a characteristic swing profile is detected, transitioning from the loading state to an active swing state;

(d) classifying the swing outcome as one of:
   (i) solid contact, identified by an acceleration spike exceeding a second threshold (greater than 8g) followed by rapid deceleration within a predetermined time window,
   (ii) miss, identified by a gradual deceleration pattern without an acceleration spike exceeding the second threshold, or
   (iii) foul contact, identified by a moderate acceleration spike (between 4g and 8g) with partial deceleration;

(e) computing per-swing metrics upon swing completion, including:
   - hand speed derived from integration of user acceleration over the swing duration,
   - peak acceleration magnitude in g-force,
   - peak rotation rate in degrees per second,
   - attack angle computed from the ratio of vertical to horizontal velocity components at the classified contact point,
   - swing duration from initiation to completion, and
   - time to contact from initiation to impact (when impact is detected);

(f) transmitting said per-swing metrics to a paired mobile device for storage and further analysis.

### Claim 3: Age-Normalized Athletic Performance Scoring System

A computer-implemented system for evaluating youth athletic performance, comprising:

(a) a reference database storing biomechanical performance norms indexed by age group, wherein said norms comprise expected ranges for at least: bat speed, peak acceleration, swing duration, hip-shoulder separation angle, and joint angle conformity, with said norms derived from Long-Term Athlete Development (LTAD) framework principles;

(b) a normalization engine configured to:
   (i) receive observed performance metrics for a player of a known age,
   (ii) retrieve the corresponding age-appropriate reference ranges from the database,
   (iii) compute normalized scores by mapping observed values to a 0-100 scale relative to the age-appropriate expected range, such that a player performing at the expected level for their age group receives a score of approximately 80;

(c) a composite scoring module that combines normalized scores across multiple metric categories including technique, power, and balance, with category weights, to produce an overall performance score;

(d) a presentation layer that displays the normalized scores alongside developmental context, enabling fair comparison between players of different ages by evaluating performance relative to developmental stage rather than absolute measurements.

### Claim 4: Biomechanical Efficiency Metric from Cross-Modal Data

A method for computing a biomechanical efficiency metric for a baseball swing, comprising:

(a) computing a video-derived body mechanics score by:
   (i) analyzing body pose estimation data across multiple video frames to determine balance stability as the variance of ankle joint positions relative to a center of gravity estimate,
   (ii) measuring joint angles at key anatomical points (elbow, shoulder, hip, knee) and computing the degree to which each falls within biomechanically ideal ranges,
   (iii) measuring hip-shoulder separation angle as an indicator of kinematic chain utilization, and
   (iv) optionally measuring bat plane efficiency as the straightness of the bat path through the strike zone;

(b) computing an IMU-derived rotational efficiency score by:
   (i) calculating the ratio of peak angular velocity (measured by gyroscope) to peak linear acceleration (measured by accelerometer), wherein a higher ratio indicates more efficient conversion of rotational body force to bat speed, and
   (ii) computing a swing smoothness metric as the inverse of the coefficient of variation of swing durations across multiple swings in a session;

(c) combining the video-derived body mechanics score and the IMU-derived rotational efficiency score using predetermined weights to produce a single biomechanical efficiency value;

(d) classifying the efficiency value into qualitative categories (excellent, good, fair, needs improvement) based on age-normalized thresholds.

---

## Dependent Claims

### Claim 5 (dependent on Claim 1)
The method of Claim 1, wherein the wrist-worn wearable device is an Apple Watch, the IMU sensors comprise a CMBatchedSensorManager operating at 800 Hz for accelerometer data and 200 Hz for device motion data on supported hardware, falling back to CMMotionManager at 100 Hz on older hardware.

### Claim 6 (dependent on Claim 1)
The method of Claim 1, wherein the body pose estimation model extracts both 2D joint positions (19 joints in normalized image coordinates) and 3D joint positions (16 joints in metric coordinates relative to the body root), and wherein the limb segment proportion calculation preferentially uses 3D joint positions when available.

### Claim 7 (dependent on Claim 1)
The method of Claim 1, further comprising computing a consistency index by:
(a) calculating the coefficient of variation for each of: hand speed, swing duration, attack angle, and rotation rate across multiple swings in a session,
(b) averaging the coefficients of variation, and
(c) converting to a 0-100 score where lower variation yields higher scores.

### Claim 8 (dependent on Claim 1)
The method of Claim 1, wherein the system operates in a graceful degradation mode, producing:
(a) full fusion results with 95% confidence when both IMU and video data are available,
(b) video-only results with 65% confidence when IMU data is unavailable, using age-based estimates for acceleration-dependent metrics, and
(c) watch-only results with 70% confidence when video data is unavailable, omitting body mechanics metrics;
and wherein the confidence score is communicated to the user interface.

### Claim 9 (dependent on Claim 2)
The method of Claim 2, wherein the swing detection operates as a finite state machine with states comprising: idle, loading, active swing, impact detected, and miss detected, with configurable transition thresholds that adapt based on a practice mode setting (standard mode requiring ball impact versus air swing mode with relaxed thresholds).

### Claim 10 (dependent on Claim 3)
The system of Claim 3, wherein the age groups comprise: 5-7, 8-9, 10-11, 12-13, 14-15, 16-17, and 18+, and wherein the lever-arm correction factor for bat speed calibration varies from 2.2 for the youngest group to 3.4 for adult players, reflecting the biomechanical relationship between wrist velocity and bat head velocity at different developmental stages.

### Claim 11 (dependent on Claim 1)
The method of Claim 1, further comprising:
(a) generating a per-swing breakdown for each swing in a multi-swing session, each comprising calibrated speed, power index, timing score, and efficiency rating;
(b) computing a speed distribution analysis including mean, standard deviation, and classification of swings into speed zones (elite, above average, average, below average);
(c) computing an improvement trend via linear regression of swing speeds over sequential swing indices within the session.

### Claim 12 (dependent on Claim 4)
The method of Claim 4, wherein the hip-shoulder separation angle is computed from video pose estimation data by:
(a) defining the hip line as the vector connecting left hip and right hip joint positions,
(b) defining the shoulder line as the vector connecting left shoulder and right shoulder joint positions,
(c) computing the angle between said lines projected onto the horizontal plane, and
(d) measuring the maximum separation angle achieved during the swing, with values exceeding 25 degrees indicating effective kinematic chain utilization.

---

## Abstract

A system and method for multi-modal baseball swing analysis combining wrist-worn inertial measurement unit (IMU) data from a consumer wearable device with video-based body pose estimation. The system performs temporal alignment of high-frequency IMU data (100-800 Hz) with video pose sequences, calibrates bat speed by scaling wrist velocity using video-derived arm segment proportions, computes cross-modal biomechanical efficiency metrics, and normalizes all scores against age-appropriate developmental references. The fusion produces more accurate and comprehensive analysis than either modality alone, with graceful degradation when only one data source is available. Real-time swing detection with impact classification enables practice session tracking without additional hardware beyond a smartphone and smartwatch.
