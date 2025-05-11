#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Maternal Health Risk Prediction Model Training Script
=====================================================
This script trains a machine learning model to predict maternal health risks
based on various health indicators. It processes training data, builds a robust
pipeline, evaluates model performance, and saves the necessary model components.

Author: Tuyizere Pacifique
Created: April 27, 2025
"""

import os
import warnings
import pandas as pd
import numpy as np
import joblib
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.exceptions import ConvergenceWarning

# Suppress specific warnings for cleaner output
warnings.filterwarnings('ignore', category=UserWarning, module='sklearn')
warnings.filterwarnings('ignore', category=ConvergenceWarning)

# Configuration constants
DATASET_FILENAME = 'Maternal Health Risk Data Set.csv'
PIPELINE_FILENAME = 'maternal_risk_pipeline.joblib'
LABEL_ENCODER_FILENAME = 'risk_level_label_encoder.joblib'
FEATURES_FILENAME = 'risk_model_features.joblib'

# Model hyperparameters
MODEL_PARAMS = {
    'n_estimators': 150,
    'max_depth': 10,
    'min_samples_split': 5,
    'min_samples_leaf': 3,
    'random_state': 42,
    'class_weight': 'balanced',
    'oob_score': True,
    'n_jobs': -1
}


def load_and_preprocess_data(filepath):
    """
    Load and preprocess the dataset.
    
    Args:
        filepath (str): Path to the CSV dataset file
        
    Returns:
        tuple: (X, y, features) - Feature DataFrame, target Series, and feature list
    """
    print(f"\n[1/6] Loading dataset: {filepath}")
    
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Dataset file '{filepath}' not found in the current directory.")
    
    # Read CSV and clean up column names
    df = pd.read_csv(filepath, skipinitialspace=True)
    df.columns = df.columns.str.strip()
    
    # Remove any unnamed or index columns
    if 'Unnamed: 0' in df.columns:
        df = df.drop('Unnamed: 0', axis=1)
    
    # Define features and target
    features = ['Age', 'SystolicBP', 'DiastolicBP', 'BS', 'BodyTemp', 'HeartRate']
    target = 'RiskLevel'
    
    # Validate that all required columns exist
    missing_cols = [col for col in features + [target] if col not in df.columns]
    if missing_cols:
        raise ValueError(f"The following required columns are missing: {missing_cols}")
    
    # Extract features and target
    X = df[features]
    y = df[target].str.strip()  # Ensure no trailing spaces in target labels
    
    # Check for missing values
    missing_counts = X.isnull().sum()
    if missing_counts.sum() > 0:
        print("\nWarning: Missing values detected in features:")
        print(missing_counts[missing_counts > 0])
        print("Filling missing values with median for each feature.")
        X = X.fillna(X.median())
    
    if y.isnull().sum() > 0:
        print(f"\nWarning: {y.isnull().sum()} missing values detected in target variable.")
        print("Filling missing target values with mode.")
        y = y.fillna(y.mode()[0])
    
    # Display dataset information
    print(f"\nDataset shape: {df.shape}")
    print("\nFeature statistics:")
    print(X.describe().round(2))
    print("\nRisk level distribution:")
    print(y.value_counts(normalize=True).round(4) * 100)
    
    return X, y, features


def encode_target(y):
    """
    Encode the target variable using LabelEncoder.
    
    Args:
        y (pandas.Series): Target variable
        
    Returns:
        tuple: (encoded_y, encoder) - Encoded target and the fitted LabelEncoder
    """
    print("\n[2/6] Encoding target variable")
    
    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)
    
    print("Risk Level Encoding Mapping:")
    for i, class_name in enumerate(label_encoder.classes_):
        print(f"  '{class_name}' -> {i}")
    
    return y_encoded, label_encoder


def create_train_test_split(X, y_encoded):
    """
    Split the dataset into training and test sets.
    
    Args:
        X (pandas.DataFrame): Feature DataFrame
        y_encoded (numpy.ndarray): Encoded target variable
        
    Returns:
        tuple: (X_train, X_test, y_train, y_test) - Split datasets
    """
    print("\n[3/6] Splitting data (80% train, 20% test)")
    
    X_train, X_test, y_train, y_test = train_test_split(
        X, y_encoded,
        test_size=0.20,
        random_state=42,
        stratify=y_encoded
    )
    
    print(f"Training set: {X_train.shape[0]} samples")
    print(f"Test set: {X_test.shape[0]} samples")
    
    return X_train, X_test, y_train, y_test


def build_and_train_pipeline(X_train, X_test, y_train, y_test, features):
    """
    Build and train the machine learning pipeline.
    
    Args:
        X_train (pandas.DataFrame): Training features
        X_test (pandas.DataFrame): Test features
        y_train (numpy.ndarray): Training target
        y_test (numpy.ndarray): Test target
        features (list): List of feature names
        
    Returns:
        sklearn.pipeline.Pipeline: Trained pipeline
    """
    print("\n[4/6] Building and training model pipeline")
    
    # Create preprocessing transformer
    numeric_transformer = Pipeline(steps=[
        ('scaler', StandardScaler())
    ])
    
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', numeric_transformer, features)
        ],
        remainder='passthrough'
    )
    
    # Create classifier and full pipeline
    classifier = RandomForestClassifier(**MODEL_PARAMS)
    
    pipeline = Pipeline(steps=[
        ('preprocessor', preprocessor),
        ('classifier', classifier)
    ])
    
    # Train the model
    print("Training model...")
    pipeline.fit(X_train, y_train)
    
    # Calculate cross-validation score
    cv_scores = cross_val_score(pipeline, X_train, y_train, cv=5)
    print(f"5-fold cross-validation accuracy: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")
    
    # Get OOB score if available
    if hasattr(classifier, 'oob_score_'):
        print(f"Out-of-Bag (OOB) accuracy: {classifier.oob_score_:.4f}")
    
    # Feature importance
    feature_importances = classifier.feature_importances_
    importance_df = pd.DataFrame({'Feature': features, 'Importance': feature_importances})
    print("\nFeature importance ranking:")
    print(importance_df.sort_values('Importance', ascending=False))
    
    return pipeline


def evaluate_model(pipeline, X_test, y_test, label_encoder):
    """
    Evaluate the trained model on the test set.
    
    Args:
        pipeline (sklearn.pipeline.Pipeline): Trained pipeline
        X_test (pandas.DataFrame): Test features
        y_test (numpy.ndarray): Test target
        label_encoder (sklearn.preprocessing.LabelEncoder): Label encoder
        
    Returns:
        float: Accuracy score
    """
    print("\n[5/6] Evaluating model performance")
    
    y_pred = pipeline.predict(X_test)
    y_proba = pipeline.predict_proba(X_test)
    
    # Convert encoded values back to labels for readability
    y_test_labels = label_encoder.inverse_transform(y_test)
    y_pred_labels = label_encoder.inverse_transform(y_pred)
    
    # Calculate accuracy
    accuracy = accuracy_score(y_test_labels, y_pred_labels)
    print(f"Test set accuracy: {accuracy:.4f}")
    
    # Generate classification report
    print("\nClassification report:")
    print(classification_report(y_test_labels, y_pred_labels, target_names=label_encoder.classes_))
    
    # Generate confusion matrix
    print("\nConfusion matrix:")
    cm = confusion_matrix(y_test_labels, y_pred_labels)
    cm_df = pd.DataFrame(cm,
                      index=[f"True: {cls}" for cls in label_encoder.classes_],
                      columns=[f"Pred: {cls}" for cls in label_encoder.classes_])
    print(cm_df)
    
    return accuracy


def save_model_components(pipeline, label_encoder, features):
    """
    Save the trained model components to disk.
    
    Args:
        pipeline (sklearn.pipeline.Pipeline): Trained pipeline
        label_encoder (sklearn.preprocessing.LabelEncoder): Label encoder
        features (list): List of feature names
    """
    print("\n[6/6] Saving model components")
    
    # Save components
    joblib.dump(pipeline, PIPELINE_FILENAME)
    joblib.dump(label_encoder, LABEL_ENCODER_FILENAME)
    joblib.dump(features, FEATURES_FILENAME)
    
    # Verify files were created
    for filename in [PIPELINE_FILENAME, LABEL_ENCODER_FILENAME, FEATURES_FILENAME]:
        file_size = os.path.getsize(filename) / (1024 * 1024)  # Size in MB
        print(f"  {filename}: {file_size:.2f} MB")


def train_and_save_model():
    """
    Main function to orchestrate the entire model training workflow.
    """
    print("=" * 80)
    print("MATERNAL HEALTH RISK PREDICTION MODEL TRAINING")
    print("=" * 80)
    
    try:
        # Process data
        X, y, features = load_and_preprocess_data(DATASET_FILENAME)
        y_encoded, label_encoder = encode_target(y)
        X_train, X_test, y_train, y_test = create_train_test_split(X, y_encoded)
        
        # Train and evaluate model
        pipeline = build_and_train_pipeline(X_train, X_test, y_train, y_test, features)
        accuracy = evaluate_model(pipeline, X_test, y_test, label_encoder)
        
        # Save components
        save_model_components(pipeline, label_encoder, features)
        
        print("\n" + "=" * 80)
        print(f"MODEL TRAINING COMPLETED SUCCESSFULLY (Test Accuracy: {accuracy:.4f})")
        print("=" * 80)
        print(f"Model components saved to current directory.")
        
    except Exception as e:
        print("\n" + "=" * 80)
        print(f"ERROR: {str(e)}")
        print("=" * 80)
        import traceback
        traceback.print_exc()


# Execute the training workflow if script is run directly
if __name__ == "__main__":
    train_and_save_model()